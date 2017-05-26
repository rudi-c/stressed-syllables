defmodule StressedSyllables.CLI do
  @moduledoc """
  Handles the parsing of command-line arguments before running the main program
  """

  def main(argv) do
    argv
    |> parse_args
    |> process
  end

  def parse_args(argv) do
    parse = OptionParser.parse(argv)

    case parse do
      { _, [ text ], _ } -> {:text, text}
      _ -> :help
    end
  end

  def process(:help) do
    IO.puts """
    Help: TODO
    """
    System.halt(0)
  end

  def process({:text, text}) do
    # For now, assume text is only one word
    IO.puts inspect StressedSyllables.Merriam.get_word(text)
  end
end
