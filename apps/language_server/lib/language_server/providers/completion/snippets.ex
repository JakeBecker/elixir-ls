defmodule ElixirLS.LanguageServer.Providers.Completion.Snippets do
  @moduledoc """
  Snippets module provider

  Extracted from https://github.com/fr1zle/vscode-elixir/blob/master/snippets/snippets.json
  """
  @snippets [
    %{
      "label" => "case",
      # Snippet
      "kind" => 15,
      "detail" => "case",
      "documentation" => "case",
      "insertText" => "case $1 do\n\t$2 ->\n\t\t$0\nend",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "cond",
      # Snippet
      "kind" => 15,
      "detail" => "cond",
      "documentation" => "cond",
      "insertText" => "cond do\n\t$1 ->\n\t\t$0\nend",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "def",
      # Snippet
      "kind" => 15,
      "detail" => "def",
      "documentation" => "def",
      "insertText" => "def $1 do\n\t$0\nend",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "test",
      # Snippet
      "kind" => 15,
      "detail" => "test",
      "documentation" => "test",
      "insertText" => "test $1 do\n\t$0\nend",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "describe",
      # Snippet
      "kind" => 15,
      "detail" => "describe",
      "documentation" => "describe",
      "insertText" => "describe $1 do\n\t$0\nend",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "defcallback",
      # Snippet
      "kind" => 15,
      "detail" => "defcallback",
      "documentation" => "defcallback",
      "insertText" => "defcallback $1 :: $0",
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "defdelegate",
      # Snippet
      "kind" => 15,
      "detail" => "defdelegate",
      "documentation" => "defdelegate",
      "insertText" => "defdelegate $1 to: $0",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "defexception",
      # Snippet
      "kind" => 15,
      "detail" => "defexception",
      "documentation" => "defexception",
      "insertText" => "defexception [${1::message}]",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "defimpl",
      # Snippet
      "kind" => 15,
      "detail" => "defimpl",
      "documentation" => "defimpl",
      "insertText" => "defimpl $1, for: $2 do\n  $0\nend",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "defmacro",
      # Snippet
      "kind" => 15,
      "detail" => "defmacro",
      "documentation" => "defmacro",
      "insertText" => "defmacro $1 do\n\t$0\nend",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "defmacrocallback",
      # Snippet
      "kind" => 15,
      "detail" => "defmacrocallback",
      "documentation" => "defmacrocallback",
      "insertText" => "defmacrocallback $1 :: $0",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "defmacrop",
      # Snippet
      "kind" => 15,
      "detail" => "defmacrop",
      "documentation" => "defmacrop",
      "insertText" => "defmacrop $1 do\n\t$0\nend",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "defmodule",
      # Snippet
      "kind" => 15,
      "detail" => "defmodule",
      "documentation" => "defmodule",
      "insertText" => "defmodule $1 do\n\t$0\nend",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "defp",
      # Snippet
      "kind" => 15,
      "detail" => "defp",
      "documentation" => "defp",
      "insertText" => "defp $1 do\n\t$0\nend",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "defprotocol",
      # Snippet
      "kind" => 15,
      "detail" => "defprotocol",
      "documentation" => "defprotocol",
      "insertText" => "defprotocol $1 do\n  $0\nend",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "defstruct",
      # Snippet
      "kind" => 15,
      "detail" => "defstruct",
      "documentation" => "defstruct",
      "insertText" => "defstruct $1: $2",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "do",
      # Snippet
      "kind" => 15,
      "detail" => "do",
      "documentation" => "do",
      "insertText" => "do\n\t$0\nend",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "@doc",
      # Snippet
      "kind" => 15,
      "detail" => "@doc",
      "documentation" => "@doc",
      "insertText" => "@doc \"\"\"\n$0\n\"\"\"",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "i",
      # Snippet
      "kind" => 15,
      "detail" => "i",
      "documentation" => "i",
      "insertText" => "inspect($0)",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "ii",
      # Snippet
      "kind" => 15,
      "detail" => "ii",
      "documentation" => "ii",
      "insertText" => "IO.inspect($0)",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "@moduledoc",
      # Snippet
      "kind" => 15,
      "detail" => "@moduledoc",
      "documentation" => "@moduledoc",
      "insertText" => "@moduledoc \"\"\"\n$0\n\"\"\"",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "@spec",
      # Snippet
      "kind" => 15,
      "detail" => "@spec",
      "documentation" => "@spec",
      "insertText" => "@spec $0",
      # snippet
      "insertTextFormat" => 2,
      "sortText" => "0"
    },
    %{
      "label" => "receive",
      # Snippet
      "kind" => 15,
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
      # Snippet
      "kind" => 15,
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