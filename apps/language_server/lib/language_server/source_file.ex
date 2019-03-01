defmodule ElixirLS.LanguageServer.SourceFile do
  import ElixirLS.LanguageServer.Protocol

  defstruct [:text, :version, dirty?: false]

  def lines(%__MODULE__{text: text}) do
    lines(text)
  end

  def lines(text) when is_binary(text) do
    String.split(text, ["\r\n", "\r", "\n"])
  end

  def apply_content_changes(source_file, []) do
    source_file
  end

  def apply_content_changes(source_file, [edit | rest]) do
    source_file =
      case edit do
        %{"range" => edited_range, "text" => new_text} when not is_nil(edited_range) ->
          update_in(source_file.text, fn text ->
            apply_edit(text, edited_range, new_text)
          end)

        %{"text" => new_text} ->
          put_in(source_file.text, new_text)
      end

    source_file =
      update_in(source_file.version, fn
        v when is_integer(v) -> v + 1
        _ -> 1
      end)

    apply_content_changes(source_file, rest)
  end

  @doc """
  Returns path from URI in a way that handles windows file:///c%3A/... URLs correctly
  """
  def path_from_uri(uri) do
    uri_path = URI.decode(URI.parse(uri).path)

    case :os.type() do
      {:win32, _} -> String.trim_leading(uri_path, "/")
      _ -> uri_path |> path_to_wsl() # if in WSL translate from Windows path
    end
  end

  def path_to_uri(path) do
    uri_path =
      path
      |> Path.expand()
      |> path_from_wsl() # if in WSL translate to Windows path
      |> URI.encode()
      |> String.replace(":", "%3A")

    cond do
      :win32 == elem(:os.type(), 0)                         -> "file:///" <> uri_path
      in_wsl?() && Regex.match?(~r/^[a-z]%3A/i, uri_path)   -> "file:///" <> uri_path
      true                                                  -> "file://" <> uri_path
    end
  end

  def full_range(source_file) do
    lines = lines(source_file)

    %{
      "start" => %{"line" => 0, "character" => 0},
      "end" => %{"line" => Enum.count(lines) - 1, "character" => String.length(List.last(lines))}
    }
  end

  def apply_edit(text, range(start_line, start_character, end_line, end_character), new_text) do
    lines_with_idx =
      text
      |> lines()
      |> Enum.with_index()

    acc =
      Enum.reduce(lines_with_idx, [], fn {line, idx}, acc ->
        cond do
          idx < start_line ->
            [[line, ?\n] | acc]

          idx == start_line ->
            [String.slice(line, 0, start_character) | acc]

          idx > start_line ->
            acc
        end
      end)

    acc = [new_text | acc]

    acc =
      Enum.reduce(lines_with_idx, acc, fn {line, idx}, acc ->
        cond do
          idx < end_line ->
            acc

          idx == end_line ->
            [[String.slice(line, end_character..-1), ?\n] | acc]

          idx > end_line ->
            [[line, ?\n] | acc]
        end
      end)

    # Remove extraneous newline from last line
    [[last_line, ?\n] | rest] = acc
    acc = [last_line | rest]

    IO.iodata_to_binary(Enum.reverse(acc))
  end

  def function_line(mod, fun, arity) do
    case ElixirSense.Core.Introspection.get_docs(mod, :docs) do
      nil ->
        nil

      docs ->
        Enum.find_value(docs, fn
          {{^fun, ^arity}, line, :def, _, _} -> line
          _ -> nil
        end)
    end
  end

  def function_def_on_line?(text, line, fun) do
    case Enum.at(lines(text), line - 1) do
      nil ->
        false

      line_text ->
        Regex.match?(Regex.compile!("^\s*def\s+#{Regex.escape(to_string(fun))}"), line_text)
    end
  end

  defp path_to_wsl(uri_path), do: path_to_wsl(uri_path, in_wsl?())

  defp path_to_wsl(uri_path, false), do: uri_path

  defp path_to_wsl("/" <> <<drive_letter::bytes-size(1)>> <> ":" <> rest_path = uri_path, true) do
    mounts = File.read!("/proc/mounts")
    {:ok, r} = Regex.compile("#{drive_letter}: (/.*#{drive_letter}) drvfs", "i")

    with [[_, mount_path] | _] <- Regex.scan(r, mounts) do
      mount_path <> rest_path
    else
      _ -> uri_path
    end
  end

  defp path_from_wsl(uri_path), do: path_from_wsl(uri_path, in_wsl?())

  defp path_from_wsl(uri_path, false), do: uri_path

  defp path_from_wsl(uri_path, true) do
    mounts =
      "/proc/mounts"
      |> File.read!()
      |> String.split("\n")
      |> Enum.filter(&Regex.match?(~r/^(.): .*/i, &1))

    find_wsl_path(uri_path, mounts)
  end

  defp find_wsl_path(uri_path, [mount_line | mounts]) do
    [[_, drive, mount_path] | _] = Regex.scan(~r/(.:) (.*) drvfs/, mount_line)

    case String.starts_with?(uri_path, mount_path) do
      true ->
        uri_path
        |> String.replace(mount_path, drive, global: false)
        |> find_wsl_path([])

      false ->
        find_wsl_path(uri_path, mounts)
    end
  end

  defp find_wsl_path(uri_path, []), do: uri_path

  defp in_wsl?, do: File.exists?("/proc/version") && Regex.match?(~r/microsoft/ui, File.read!("/proc/version"))

end
