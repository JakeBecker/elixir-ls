defmodule ElixirLS.LanguageServer.Providers.Completion.Snippets do
  @moduledoc """
  Snippets module provider

  Extracted from https://github.com/fr1zle/vscode-elixir/blob/master/snippets/snippets.json
  """
  @snippets [
    %{
      "label" => "case",
      # Function
      "kind" => 3,
      "detail" => "case",
      "documentation" => "case",
      "insertText" => "case $1 do\n\t$2 ->\n\t\t$0\nend",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "cond",
      # Function
      "kind" => 3,
      "detail" => "cond",
      "documentation" => "cond",
      "insertText" => "cond do\n\t$1 ->\n\t\t$0\nend",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "def",
      # Function
      "kind" => 3,
      "detail" => "def",
      "documentation" => "def",
      "insertText" => "def $1 do\n\t$0\nend",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "test",
      # Function
      "kind" => 3,
      "detail" => "test",
      "documentation" => "test",
      "insertText" => "test $1 do\n\t$0\nend",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "describe",
      # Function
      "kind" => 3,
      "detail" => "describe",
      "documentation" => "describe",
      "insertText" => "describe $1 do\n\t$0\nend",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "defcallback",
      # Function
      "kind" => 3,
      "detail" => "defcallback",
      "documentation" => "defcallback",
      "insertText" => "defcallback $1 :: $0",
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "defdelegate",
      # Function
      "kind" => 3,
      "detail" => "defdelegate",
      "documentation" => "defdelegate",
      "insertText" => "defdelegate $1 to: $0",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "defexception",
      # Function
      "kind" => 3,
      "detail" => "defexception",
      "documentation" => "defexception",
      "insertText" => "defexception [${1::message}]",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "defimpl",
      # Function
      "kind" => 3,
      "detail" => "defimpl",
      "documentation" => "defimpl",
      "insertText" => "defimpl $1, for: $2 do\n  $0\nend",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "defmacro",
      # Function
      "kind" => 3,
      "detail" => "defmacro",
      "documentation" => "defmacro",
      "insertText" => "defmacro $1 do\n\t$0\nend",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "defmacrocallback",
      # Function
      "kind" => 3,
      "detail" => "defmacrocallback",
      "documentation" => "defmacrocallback",
      "insertText" => "defmacrocallback $1 :: $0",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "defmacrop",
      # Function
      "kind" => 3,
      "detail" => "defmacrop",
      "documentation" => "defmacrop",
      "insertText" => "defmacrop $1 do\n\t$0\nend",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "defmodule",
      # Function
      "kind" => 3,
      "detail" => "defmodule",
      "documentation" => "defmodule",
      "insertText" => "defmodule $1 do\n\t$0\nend",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "defp",
      # Function
      "kind" => 3,
      "detail" => "defp",
      "documentation" => "defp",
      "insertText" => "defp $1 do\n\t$0\nend",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "defprotocol",
      # Function
      "kind" => 3,
      "detail" => "defprotocol",
      "documentation" => "defprotocol",
      "insertText" => "defprotocol $1 do\n  $0\nend",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "defstruct",
      # Function
      "kind" => 3,
      "detail" => "defstruct",
      "documentation" => "defstruct",
      "insertText" => "defstruct $1: $2",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "do",
      # Function
      "kind" => 3,
      "detail" => "do",
      "documentation" => "do",
      "insertText" => "do\n\t$0\nend",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "@doc",
      # Function
      "kind" => 3,
      "detail" => "@doc",
      "documentation" => "@doc",
      "insertText" => "@doc \"\"\"\n$0\n\"\"\"",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "i",
      # Function
      "kind" => 3,
      "detail" => "i",
      "documentation" => "i",
      "insertText" => "inspect($0)",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "ii",
      # Function
      "kind" => 3,
      "detail" => "ii",
      "documentation" => "ii",
      "insertText" => "IO.inspect($0)",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "@moduledoc",
      # Function
      "kind" => 3,
      "detail" => "@moduledoc",
      "documentation" => "@moduledoc",
      "insertText" => "@moduledoc \"\"\"\n$0\n\"\"\"",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "@spec",
      # Function
      "kind" => 3,
      "detail" => "@spec",
      "documentation" => "@spec",
      "insertText" => "@spec $0",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "receive",
      # Function
      "kind" => 3,
      "detail" => "receive",
      "documentation" => "receive",
      "insertText" =>
        "receive do\n\t${1:{${2::message_type}, ${3:value}\\}} ->\n    ${0:# code}\nend\n",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "require",
      # Function
      "kind" => 3,
      "detail" => "require",
      "documentation" => "require",
      "insertText" => "require $0",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    }
  ]

  def get_snippets do
    @snippets
  end
end