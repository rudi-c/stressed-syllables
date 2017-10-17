defmodule StressedSyllablesTest do
  use ExUnit.Case
  doctest StressedSyllables

  alias StressedSyllables.MerriamWord.Word
  import StressedSyllables.MerriamWord, only: [ parse: 4 ]

  alias StressedSyllables.Stressed.WordStressData
  import StressedSyllables.Stressed, only: [ get_stress_information: 2 ]

  alias StressedSyllables.NLP.WordInfo

  test "parse a normal word" do
    result = parse(
      "constitution",
      "noun",
      "con·sti·tu·tion",
      "ˌkän(t)-stə-ˈtü-shən")
    %Word{ pofspeech: pofspeech, syllables: syllables, pronounciation: pronounciation } = result
    assert pofspeech == "NOUN"
    assert syllables == ["con", "sti", "tu", "tion"]
    assert pronounciation == ["ˌkän", "stə", "ˈtü", "shən"]
  end

  test "parse word alternate syllable" do
    result = parse(
      "entirely",
      "adverb",
      "en·tire·ly",
      "in-ˈtī(-ə)r-lē")
    %Word{ pofspeech: pofspeech, syllables: syllables, pronounciation: pronounciation } = result
    assert pofspeech == "ADV"
    assert syllables == ["en", "tire", "ly"]
    assert pronounciation == ["in", "ˈtīr", "lē"]
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

  test "parse word with pronounciation data containing 'also'" do
    result = parse(
      "conduct",
      "noun",
      "con·duct",
      "kən-ˈdəkt also ˈkän-ˌdəkt")
    %Word{ pronounciation: pronounciation } = result
    pronounciation == ["kən", "ˈdəkt"]
  end

  test "parse word with pronounciation data containing semicolon" do
    result = parse(
      "interest",
      "noun",
      "in·ter·est",
      "ˈin-t(ə-)rəst;")
    %Word{ pronounciation: pronounciation } = result
    pronounciation == ["ˈin", "trəst"]
  end

  test "parse word with no syllables" do
    result = parse(
      "or",
      "conjunction",
      "",
      "ər")
    assert result == nil
  end

  test "find stress with where a definition is only secondary stress" do
    result = get_stress_information(
      %WordInfo{ word: "during", index: -1, pofspeech: "ADP" },
      %{
        "during" => [
          %Word{ pofspeech: "ADP", syllables: ["dur", "ing"], pronounciation: ["ˈdu̇r", "iŋ"] },
          %Word{ pofspeech: "ADP", syllables: ["dur", "ing"], pronounciation: ["ˌdu̇r", "iŋ"] }
        ]
      }
    )
    %WordStressData{ stress_information: stress_information } = result
    assert stress_information == {:syllables, ["dur", "ing"], 0}
  end
end
