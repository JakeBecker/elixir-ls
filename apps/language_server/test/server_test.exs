defmodule ElixirLS.LanguageServer.ServerTest do
  alias ElixirLS.LanguageServer.{Server, Protocol, SourceFile}
  alias ElixirLS.Utils.PacketCapture
  use ElixirLS.Utils.MixTest.Case, async: false
  use Protocol

  doctest(Server)

  setup do
    {:ok, server} = Server.start_link()
    {:ok, packet_capture} = PacketCapture.start_link(self())
    Process.group_leader(server, packet_capture)

    {:ok, %{server: server}}
  end

  test "hover", %{server: server} do
    uri = "file:///file.ex"
    code = ~S(
      defmodule MyModule do
        use GenServer
      end
    )

    Server.receive_packet(server, did_open(uri, "elixir", 1, code))
    Server.receive_packet(server, hover_req(1, uri, 2, 17))

    assert_receive response(1, %{
                     "contents" => "> GenServer" <> _,
                     "range" => %{
                       "start" => %{"line" => 2, "character" => 12},
                       "end" => %{"line" => 2, "character" => 21}
                     }
                   })
  end

  test "auto complete", %{server: server} do
    uri = "file:///file.ex"
    code = ~S(
    defmodule MyModule do
      def my_fn, do: GenSer
    end
    )

    Server.receive_packet(server, did_open(uri, "elixir", 1, code))
    Server.receive_packet(server, completion_req(1, uri, 2, 25))

    assert_receive response(1, %{
                     "isIncomplete" => true,
                     "items" => [
                       %{
                         "detail" => "module",
                         "documentation" => _,
                         "kind" => 9,
                         "label" => "GenServer"
                       }
                       | _
                     ]
                   })
  end

  test "go to definition", %{server: server} do
    uri = "file:///file.ex"
    code = ~S(
      defmodule MyModule do
        use GenServer
      end
    )

    Server.receive_packet(server, did_open(uri, "elixir", 1, code))
    Server.receive_packet(server, definition_req(1, uri, 2, 17))

    uri = "file://" <> to_string(GenServer.module_info()[:compile][:source])

    assert_receive response(1, %{
                     "range" => %{
                       "end" => %{"character" => 0, "line" => 0},
                       "start" => %{"character" => 0, "line" => 0}
                     },
                     "uri" => ^uri
                   })
  end

  test "requests cancellation", %{server: server} do
    Server.receive_packet(server, hover_req(1, "file:///file.ex", 1, 1))
    Server.receive_packet(server, cancel_request(1))

    assert_receive %{
      "error" => %{"code" => -32800, "message" => "Request cancelled"},
      "id" => 1,
      "jsonrpc" => "2.0"
    }
  end

  test "responses are sent in order of request regardless of completion order", %{server: server} do
    for id <- 1..3, do: Server.receive_packet(server, hover_req(id, "file:///file.ex", 1, 1))
    for id <- 3..1, do: Server.receive_packet(server, cancel_request(id))

    for id <- 1..3 do
      receive do
        message -> assert %{"id" => ^id, "error" => %{"code" => -32800}} = message
      end
    end
  end

  test "formatter", %{server: server} do
    uri = "file:///file.ex"
    code = ~S(
    defmodule MyModule do
    def my_fn do
    :ok
    end
    end
    )

    Server.receive_packet(server, did_open(uri, "elixir", 1, code))
    Server.receive_packet(server, formatting_req(1, uri, %{}))

    assert_receive response(1, [
                     %{
                       "newText" => "defmodule MyModule do\n  def my_fn do\n    :ok\n  end\nend",
                       "range" => %{
                         "end" => %{"character" => 4, "line" => 6},
                         "start" => %{"character" => 0, "line" => 0}
                       }
                     }
                   ])
  end

  test "signature help", %{server: server} do
    uri = "file:///file.ex"
    code = ~S[
    defmodule MyModule do
      def my_fn do
        IO.inspect()
      end
    end
    ]

    Server.receive_packet(server, did_open(uri, "elixir", 1, code))
    Server.receive_packet(server, signature_help_req(1, uri, 3, 19))

    assert_receive response(1, %{
                     "activeParameter" => 0,
                     "activeSignature" => 0,
                     "signatures" => [
                       %{
                         "documentation" =>
                           "@spec inspect(Inspect.t, keyword) :: String.t\nInspects the given argument according to the `Inspect` protocol.\nThe second argument is a keyword list with options to control\ninspection.",
                         "label" => "inspect(term, opts \\\\ [])",
                         "parameters" => [%{"label" => "term"}, %{"label" => "opts \\\\ []"}]
                       }
                     ]
                   })
  end

  test "reports build diagnostics", %{server: server} do
    in_fixture(__DIR__, "build_errors", fn ->
      root_uri = SourceFile.path_to_uri(File.cwd!())
      error_file = SourceFile.path_to_uri("lib/has_error.ex")

      Server.receive_packet(server, initialize_req(1, root_uri, %{}))
      Server.receive_packet(server, notification("initialized"))

      assert_receive notification("textDocument/publishDiagnostics", %{
                       "uri" => ^error_file,
                       "diagnostics" => [
                         %{
                           "message" =>
                             "** (CompileError) lib/has_error.ex:4: undefined function does_not_exist" <>
                               _,
                           "range" => %{"end" => %{"line" => 3}, "start" => %{"line" => 3}},
                           "severity" => 1
                         }
                       ]
                     })
    end)
  end

  test "reports error if no mixfile", %{server: server} do
    in_fixture(__DIR__, "no_mixfile", fn ->
      root_uri = SourceFile.path_to_uri(File.cwd!())
      mixfile_uri = SourceFile.path_to_uri("mix.exs")
      Server.receive_packet(server, initialize_req(1, root_uri, %{}))
      Server.receive_packet(server, notification("initialized"))

      Server.receive_packet(
        server,
        did_change_configuration(%{"elixirLS" => %{"dialyzerEnabled" => false}})
      )

      assert_receive notification("textDocument/publishDiagnostics", %{
                       "uri" => ^mixfile_uri,
                       "diagnostics" => [
                         %{
                           "message" => "No mixfile found in project root",
                           "severity" => 1
                         }
                       ]
                     }),
                     5000
    end)
  end
end