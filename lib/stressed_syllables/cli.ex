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
    parse = OptionParser.parse(argv, switches: [ file: :string ],
                                     aliases:  [ f: :file ])

    case parse do
      { [ file: filename ], _, _ } ->
        {:text, File.read! filename}
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
    StressedSyllables.Stressed.find_in_text(text)
    |> StressedSyllables.Formatter.print(text)
  end
end
