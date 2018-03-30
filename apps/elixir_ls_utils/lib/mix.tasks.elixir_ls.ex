defmodule Mix.Tasks.ElixirLs do
  use Mix.Task

  @shortdoc "Runs Elixir Language Server"
  def run(_args) do
    ElixirLS.LanguageServer.CLI.main()
  end
end
