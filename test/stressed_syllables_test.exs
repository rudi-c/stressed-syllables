defmodule StressedSyllablesTest do
  use ExUnit.Case
  doctest StressedSyllables

  alias StressedSyllables.MerriamWord.Word
  import StressedSyllables.MerriamWord, only: [ parse: 4 ]

  test "parse a normal word" do
    result = parse(
      "constitution",
      "noun",
      "con·sti·tu·tion",
      "ˌkän(t)-stə-ˈtü-shən")
    %Word{ pofspeech: pofspeech, syllables: syllables, pronounciation: pronounciation } = result
    assert pofspeech == "NOUN"
    assert syllables == ["con", "sti", "tu", "tion"]
    assert pronounciation == ["ˌkän(t)", "stə", "ˈtü", "shən"]
  end

  test "parse geographical name" do
    result = parse(
      "colorado",
      "name",
      "Col·o·ra·do",
      "ˌkä-lə-ˈra-(ˌ)dō")
    %Word{ pofspeech: pofspeech } = result
    assert pofspeech == "PNOUN"
  end

  test "parse plural noun" do
    result = parse(
      "politics",
      "noun, plural in form but singular or plural in construction",
      "pol·i·tics",
      "ˈpä-lə-ˌtiks")
    %Word{ pofspeech: pofspeech } = result
    assert pofspeech == "NOUN"
  end

  test "parse attributive noun" do
    result = parse(
      "company",
      "noun, often attributive",
      "com·pa·ny",
      "ˈkəmp-nē")
    %Word{ pofspeech: pofspeech } = result
    assert pofspeech == "NOUN"
  end

  test "parse transitive verb" do
  end

  test "parse word with pronounciation data" do
  end

  test "parse word with incomplete pronounciation data" do
    result = parse(
      "meaningful",
      "adjective",
      "mean·ing·ful",
      "-fəl")
    assert result == nil
  end

  test "parse word with no syllables" do
    result = parse(
      "or",
      "conjunction",
      "",
      "ər")
    assert result == nil
  end
end
