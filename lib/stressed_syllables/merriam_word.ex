defmodule StressedSyllables.MerriamWord do
  require Logger

  @moduledoc """
  Parses out the pronounciation and stressed syllables.
  """

  defmodule Word do
    defstruct pofspeech: "", syllables: [], pronounciation: []
  end

  @pronounciation_regex ~r/\\(.*)\\/

  def parse(word, type, syllables, pronounciation) do
    cond do
      not Regex.match?(@pronounciation_regex, pronounciation) ->
        # The pronounciation data could be missing entirely
        nil
      String.contains?(pronounciation, "same as") ->
        # TODO: We might not need to throw away this case
        nil
      String.starts_with?(pronounciation, "\\-") ->
        # If the pronounciation starts with a dash, it is probable that it only
        # contains a subset of the syllables which does not help us.
        # e.g. Searching for "meaningful" returns results with "\mē-niŋ-fəl\"
        # as expected, but also results with just "\-fəl\"
        nil
      String.length(syllables) == 0 ->
        # Missing syllables
        nil
      true ->
        parsed = parse_syllables(syllables)
        spacy_pofspeech = merriam_to_spacy(word, type)
        # This is to deal with situations such as searching for the word "file"
        # which returns a result for filé, an entirely different word.
        if syllables_is_word_subset?(parsed, word) do
          %Word{ pofspeech: spacy_pofspeech,
            syllables: parsed,
            pronounciation: parse_pronounciation(pronounciation)
          }
        else
          nil
        end
    end
  end

  defp merriam_to_spacy(word, pofspeech) do
    case pofspeech do
      "noun"        -> "NOUN"
      "pronoun"     -> "PRON"
      "adverb"      -> "ADV"
      "verb"        -> "VERB"
      "adjective"   -> "ADJ"
      "conjunction" -> "ADP"
      "preposition" -> "ADP"
      pofs ->
        cond do
          # e.g. geographical name (e.g. yosemite)
          String.ends_with?(pofs, "name") -> "PNOUN"
          # e.g. transitive verb
          String.ends_with?(pofs, "verb") -> "VERB"
          # e.g. noun, plural (e.g. fewer, politics)
          # e.g. noun, often attributive (e.g. company)
          String.contains?(pofs, "noun") -> "NOUN"
          true ->
            Logger.warn "Unknown type '#{pofspeech}' for '#{word}'"
            ""
        end
    end
  end

  defp parse_syllables(syllables) do
    syllables
    |> String.downcase
    |> String.split("·")
  end

  defp parse_pronounciation(str) do
    [_, pronounciation] = Regex.run(@pronounciation_regex, str)
    [first | _ ] = String.split(pronounciation, [",", " also "])
    String.split(first, "-")
  end

  defp syllables_is_word_subset?(syllables, word) do
    {:ok, regex} =
      syllables
      |> Enum.join(".*")
      |> Regex.compile
    Regex.match?(regex, String.downcase(word))
  end
end
