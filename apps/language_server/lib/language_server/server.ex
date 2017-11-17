defmodule ElixirLS.LanguageServer.Server do
  @moduledoc """
  Language Server Protocol server

  This server tracks open files, attempts to rebuild the project when a file changes, and handles
  requests from the IDE (for things like autocompletion, hover, etc.)

  Notifications from the IDE are handled synchronously, whereas requests can be handled sychronously
  or asynchronously.

  When possible, handling the request asynchronously has several advantages. The asynchronous
  request handling cannot modify the server state.  That way, if the process handling the request
  crashes, we can report that error to the client and continue knowing that the state is
  uncorrupted. Also, asynchronous requests can be cancelled by the client if they're taking too long
  or the user no longer cares about the result. Regardless of completion order, the protocol
  specifies that requests must be replied to in the order they are received.
  """

  use GenServer
  alias ElixirLS.LanguageServer.{SourceFile, Build, Protocol, JsonRpc, Dialyzer}

  alias ElixirLS.LanguageServer.Providers.{
    Completion,
    Hover,
    Definition,
    Formatting,
    SignatureHelp
  }

  use Protocol

  defstruct [
    :build_ref,
    :dialyzer_sup,
    :dialyzer_name,
    :client_capabilities,
    :root_uri,
    build_diagnostics: [],
    dialyzer_diagnostics: [],
    needs_build?: false,
    received_shutdown?: false,
    requests: [],
    settings: %{},
    source_files: %{}
  ]

  defmodule Request do
    defstruct [:id, :status, :pid, :ref, :result, :error_type, :error_msg]
  end

  ## Client API

  def start_link(name \\ nil) do
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  def receive_packet(server \\ __MODULE__, packet) do
    GenServer.cast(server, {:receive_packet, packet})
  end

  def build_finished(server \\ __MODULE__, result) do
    GenServer.cast(server, {:build_finished, result})
  end

  def dialyzer_finished(server \\ __MODULE__, result) do
    GenServer.cast(server, {:dialyzer_finished, result})
  end

  def rebuild(server \\ __MODULE__) do
    GenServer.cast(server, :rebuild)
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, %__MODULE__{}}
  end

  def handle_call({:request_finished, id, {:error, type, msg}}, _from, state) do
    state = update_request(state, id, &%{&1 | status: :error, error_type: type, error_msg: msg})
    {:reply, :ok, send_responses(state)}
  end

  def handle_call({:request_finished, id, {:ok, result}}, _from, state) do
    state = update_request(state, id, &%{&1 | status: :ok, result: result})
    {:reply, :ok, send_responses(state)}
  end

  def handle_call(msg, from, state) do
    super(msg, from, state)
  end

  def handle_cast({:build_finished, {status, diagnostics}}, state)
      when status in [:ok, :noop, :error] and is_list(diagnostics) do
    {:noreply, handle_build_result(status, diagnostics, state)}
  end

  # Pre Elixir 1.6, we can't get diagnostics from builds
  def handle_cast({:build_finished, _}, state) do
    {:noreply, handle_build_result(:ok, [], state)}
  end

  def handle_cast({:dialyzer_finished, {status, diagnostics}}, state) do
    {:noreply, handle_dialyzer_result(status, diagnostics, state)}
  end

  def handle_cast({:receive_packet, request(id, _, _) = packet}, state) do
    {request, state} =
      case handle_request(packet, state) do
        {:ok, result, state} ->
          {%Request{id: id, status: :ok, result: result}, state}

        {:error, type, msg, state} ->
          {%Request{id: id, status: :error, error_type: type, error_msg: msg}, state}

        {:async, fun, state} ->
          {pid, ref} = handle_request_async(id, fun)
          {%Request{id: id, status: :async, pid: pid, ref: ref}, state}
      end

    state = %{state | requests: state.requests ++ [request]}
    {:noreply, send_responses(state)}
  end

  def handle_cast({:receive_packet, notification(_) = packet}, state) do
    {:noreply, handle_notification(packet, state)}
  end

  def handle_cast(:rebuild, state) do
    {:noreply, trigger_build(state)}
  end

  def handle_cast(msg, state) do
    super(msg, state)
  end

  def handle_info({:DOWN, ref, _, _pid, reason}, %{build_ref: ref} = state) do
    state = put_in(state.build_ref, nil)

    state =
      case reason do
        :normal -> state
        _ -> handle_build_result(:error, [Build.exception_to_diagnostic(reason)], state)
      end

    state = if state.needs_build?, do: trigger_build(state), else: state
    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, _pid, :normal}, state) do
    state =
      update_request_by_ref(state, ref, fn
        %{status: :async} = req ->
          error_msg = "Internal error: Request ended without result"

          %{
            req
            | ref: nil,
              pid: nil,
              status: :error,
              error_type: :internal_error,
              error_msg: error_msg
          }

        req ->
          %{req | ref: nil, pid: nil}
      end)

    {:noreply, send_responses(state)}
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, state) do
    state =
      update_request_by_ref(state, ref, fn
        %{status: :async} = req ->
          error_msg = "Internal error: " <> Exception.format_exit(reason)

          %{
            req
            | ref: nil,
              pid: nil,
              status: :error,
              error_type: :internal_error,
              error_msg: error_msg
          }

        req ->
          %{req | ref: nil, pid: nil}
      end)

    {:noreply, send_responses(state)}
  end

  def handle_info(info, state) do
    super(info, state)
  end

  ## Helpers

  defp find_and_update(list, find_fn, update_fn) do
    idx = Enum.find_index(list, find_fn)

    if idx do
      List.update_at(list, idx, update_fn)
    else
      list
    end
  end

  defp handle_notification(notification("initialized"), state) do
    trigger_build(state)
  end

  defp handle_notification(notification("$/setTraceNotification"), state) do
    # noop
    state
  end

  defp handle_notification(cancel_request(id), state) do
    state =
      update_request(state, id, fn
        %{status: :async, pid: pid} = req ->
          Process.exit(pid, :kill)
          %{req | pid: nil, ref: nil, status: :error, error_type: :request_cancelled}

        req ->
          req
      end)

    send_responses(state)
  end

  defp handle_notification(did_change_configuration(settings), state) do
    settings = Map.get(settings, "elixirLS", %{})

    enable_dialyzer = Dialyzer.supported?() && Map.get(settings, "dialyzerEnabled", true)

    state =
      cond do
        enable_dialyzer and state.dialyzer_sup == nil ->
          {:ok, pid} = Dialyzer.Supervisor.start_link(SourceFile.path_from_uri(state.root_uri))
          %{state | dialyzer_sup: pid}

        not enable_dialyzer and state.dialyzer_sup != nil ->
          Process.exit(state.dialyzer_sup, :normal)
          %{state | dialyzer_sup: nil}

        true ->
          state
      end

    trigger_build(%{state | settings: settings})
  end

  defp handle_notification(notification("exit"), state) do
    System.halt(0)
    state
  end

  defp handle_notification(did_open(uri, _language_id, version, text), state) do
    source_file = %SourceFile{text: text, version: version}

    Build.publish_file_diagnostics(
      uri,
      state.build_diagnostics ++ state.dialyzer_diagnostics,
      source_file
    )

    put_in(state.source_files[uri], source_file)
  end

  defp handle_notification(did_close(uri), state) do
    %{state | source_files: Map.delete(state.source_files, uri)}
  end

  defp handle_notification(did_change(uri, version, content_changes), state) do
    update_in(state.source_files[uri], fn source_file ->
      source_file = %{source_file | version: version}
      SourceFile.apply_content_changes(source_file, content_changes)
    end)
  end

  defp handle_notification(did_save(_uri), state) do
    trigger_build(state)
  end

  defp handle_notification(did_change_watched_files(changes), state) do
    needs_build =
      Enum.any?(changes, fn %{"uri" => uri, "type" => type} ->
        Path.extname(uri) in [".ex", ".exs", ".erl", ".yrl", ".xrl", ".eex"] and
          (type in [1, 3] or not Map.has_key?(state.source_files, uri))
      end)

    if needs_build, do: trigger_build(state), else: state
  end

  defp handle_notification(notification(_, _) = packet, state) do
    IO.warn("Received unmatched notification: #{inspect(packet)}")
    state
  end

  defp handle_request(initialize_req(_id, root_uri, client_capabilities), state) do
    show_version_warnings()

    state =
      case root_uri do
        "file://" <> _ ->
          root_path = SourceFile.path_from_uri(root_uri)
          File.cd!(root_path)
          %{state | root_uri: root_uri}

        nil ->
          state
      end

    state = %{state | client_capabilities: client_capabilities}
    {:ok, %{"capabilities" => server_capabilities()}, state}
  end

  defp handle_request(request(_id, "shutdown", _params), state) do
    {:ok, nil, %{state | received_shutdown?: true}}
  end

  defp handle_request(definition_req(_id, uri, line, character), state) do
    fun = fn ->
      {:ok, Definition.definition(state.source_files[uri].text, line, character)}
    end

    {:async, fun, state}
  end

  defp handle_request(hover_req(_id, uri, line, character), state) do
    fun = fn ->
      {:ok, Hover.hover(state.source_files[uri].text, line, character)}
    end

    {:async, fun, state}
  end

  defp handle_request(completion_req(_id, uri, line, character), state) do
    snippets_supported =
      get_in(state.client_capabilities, [
        "textDocument",
        "completion",
        "completionItem",
        "snippetSupport"
      ]) != false

    fun = fn ->
      {
        :ok,
        Completion.completion(state.source_files[uri].text, line, character, snippets_supported)
      }
    end

    {:async, fun, state}
  end

  defp handle_request(formatting_req(_id, uri, _options), state) do
    fun = fn -> Formatting.format(state.source_files[uri], state.root_uri) end
    {:async, fun, state}
  end

  defp handle_request(signature_help_req(_id, uri, line, character), state) do
    fun = fn -> SignatureHelp.signature(state.source_files[uri], line, character) end
    {:async, fun, state}
  end

  defp handle_request(request(_, _, _) = req, state) do
    IO.inspect(req, label: "Unmatched request")
    {:error, :invalid_request, nil, state}
  end

  defp handle_request_async(id, func) do
    parent = self()

    Process.spawn(
      fn ->
        result = func.()
        GenServer.call(parent, {:request_finished, id, result}, :infinity)
      end,
      [:monitor]
    )
  end

  defp send_responses(state) do
    case state.requests do
      [%Request{id: id, status: :ok, result: result} | rest] ->
        JsonRpc.respond(id, result)
        send_responses(%{state | requests: rest})

      [%Request{id: id, status: :error, error_type: error_type, error_msg: error_msg} | rest] ->
        JsonRpc.respond_with_error(id, error_type, error_msg)
        send_responses(%{state | requests: rest})

      _ ->
        state
    end
  end

  defp server_capabilities do
    %{
      "textDocumentSync" => 1,
      "hoverProvider" => true,
      # Required to make autocomplete work in other editors
      "completionProvider" => %{
        # This activate `completionItem/resolve` send by the client
        resolveProvider: false,
        triggerCharacters: ["."]
      },
      "definitionProvider" => true,
      "documentFormattingProvider" => Formatting.supported?(),
      "signatureHelpProvider" => %{"triggerCharacters" => ["("]}
    }
  end

  defp update_request(state, id, update_fn) do
    update_in(state.requests, fn requests ->
      find_and_update(requests, &(&1.id == id), update_fn)
    end)
  end

  defp update_request_by_ref(state, ref, update_fn) do
    update_in(state.requests, fn requests ->
      find_and_update(requests, &(&1.ref == ref), update_fn)
    end)
  end

  # Build

  defp trigger_build(state) do
    if build_enabled?(state) and state.build_ref == nil do
      {_pid, build_ref} = Build.build(self(), SourceFile.path_from_uri(state.root_uri))
      %__MODULE__{state | build_ref: build_ref, needs_build?: false}
    else
      %__MODULE__{state | needs_build?: true}
    end
  end

  defp dialyze(state) do
    warn_opts =
      state.settings
      |> Map.get("dialyzerWarnOpts", [])
      |> Enum.map(&String.to_atom/1)

    if dialyzer_enabled?(state), do: Dialyzer.analyze(warn_opts)
    state
  end

  defp handle_build_result(status, diagnostics, state) do
    old_diagnostics = state.build_diagnostics ++ state.dialyzer_diagnostics
    state = put_in(state.build_diagnostics, diagnostics)

    state =
      cond do
        state.needs_build? ->
          state

        status == :error or not dialyzer_enabled?(state) ->
          put_in(state.dialyzer_diagnostics, [])

        true ->
          dialyze(state)
      end

    publish_diagnostics(
      state.build_diagnostics ++ state.dialyzer_diagnostics,
      old_diagnostics,
      state.source_files
    )

    state
  end

  defp handle_dialyzer_result(_status, diagnostics, state) do
    old_diagnostics = state.build_diagnostics ++ state.dialyzer_diagnostics
    state = put_in(state.dialyzer_diagnostics, diagnostics)

    publish_diagnostics(
      state.build_diagnostics ++ state.dialyzer_diagnostics,
      old_diagnostics,
      state.source_files
    )

    state
  end

  defp build_enabled?(state) do
    match?("file://" <> _, state.root_uri)
  end

  defp dialyzer_enabled?(state) do
    Dialyzer.supported?() and build_enabled?(state) and state.dialyzer_sup != nil
  end

  defp publish_diagnostics(new_diagnostics, old_diagnostics, source_files) do
    files =
      Enum.uniq(Enum.map(new_diagnostics, & &1.file) ++ Enum.map(old_diagnostics, & &1.file))

    for file <- files,
        uri = SourceFile.path_to_uri(file),
        do: Build.publish_file_diagnostics(uri, new_diagnostics, Map.get(source_files, uri))
  end

  defp show_version_warnings do
    unless Version.match?(System.version(), ">= 1.6.0-dev") do
      JsonRpc.show_message(
        :info,
        "Upgrade to Elixir >= 1.6.0-dev for build warnings and errors and for code formatting. " <>
          "(Currently v#{System.version()})"
      )
    end

    {otp_version, _} = Integer.parse(to_string(:erlang.system_info(:otp_release)))

    warning =
      cond do
        otp_version < 19 ->
          "Upgrade Erlang to version OTP 20 for debugging support and automatic, " <>
            "incremental Dialyzer integration."

        otp_version < 20 ->
          "Upgrade Erlang to version OTP 20 for automatic, incremental Dialyzer integration."

        otp_version > 20 ->
          "ElixirLS Dialyzer integration has not been tested with Erlang versions other than " <>
            "OTP 20. To disable, set \"elixirLS.enableDialyzer\" to false."

        true ->
          nil
      end

    if warning != nil,
      do: JsonRpc.show_message(:info, warning <> " (Currently OTP #{otp_version})")
  end
end