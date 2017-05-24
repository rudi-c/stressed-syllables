defmodule StressedSyllablesTest do
  use ExUnit.Case
  doctest StressedSyllables

  import StressedSyllables.CLI, only: [ parse_args: 1 ]

  test "displays help if now arguments" do
    assert parse_args([]) == :help
  end

  test "parses the input file" do
    assert parse_args([ "text.txt" ]) == "text.txt"
  end
end
