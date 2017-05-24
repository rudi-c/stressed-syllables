defmodule StressedSyllables.CLI do
  @moduledoc """
  Handles the parsing of command-line arguments before running the main program
  """

  def run(argv) do
    argv |> parse_args
  end

  def parse_args(argv) do
    parse = OptionParser.parse(argv)

    case parse do
      { _, [ filename ], _ } -> filename
      _ -> :help
    end
  end
end
