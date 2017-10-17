defmodule StressedSyllables.MerriamWord do
  require Logger

  @moduledoc """
  Parses out the pronounciation and stressed syllables.
  """

  defmodule Word do
    defstruct pofspeech: "", syllables: [], pronounciation: []
  end

  @spec parse(String.t, String.t, String.t, String.t) :: (%Word{}) | nil
  def parse(word, type, syllables, pronounciation) do
    cond do
      String.contains?(pronounciation, "same as") ->
        # TODO: We might not need to throw away this case
        Logger.debug "Parsing '#{word}' failed: contains 'same as'"
        nil
      String.starts_with?(pronounciation, "-") ->
        # If the pronounciation starts with a dash, it is probable that it only
        # contains a subset of the syllables which does not help us.
        # e.g. Searching for "meaningful" returns results with "\mē-niŋ-fəl\"
        # as expected, but also results with just "\-fəl\"
        Logger.debug "Parsing '#{word}' failed: pronounciation starts with dash, probably a subset"
        nil
      String.length(syllables) == 0 ->
        Logger.debug "Parsing '#{word}' failed: no syllables"
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
          Logger.debug "Parsing '#{word}' failed: syllables are not a subset of the word"
          nil
        end
    end
  end

  @spec merriam_to_spacy(String.t, String.t) :: String.t
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

  @spec parse_syllables(String.t) :: list(String.t)
  defp parse_syllables(syllables) do
    syllables
    |> String.downcase
    |> String.split("·")
  end

  # Most of the time, each pronounciation comes is its own .pr tag,
  # but sometimes you still get something like
  # <span class="pr">something also something</span> so you still need to do
  # the work of splitting by commas, semicolons and "also"s
  #
  # Also make sure to handle syllables that have a - inside of it that indicates
  # alternate (?) options, which we can safely (?) get rid of
  @alternate_regex ~r/\([^\(]*\)/
  @spec parse_pronounciation(String.t) :: list(String.t)
  defp parse_pronounciation(pronounciation) do
    [first | _ ] = String.split(pronounciation, [",", " also ", ";"])
    Regex.replace(@alternate_regex, first, "")
    |> String.split("-")
  end

  @spec syllables_is_word_subset?(list(String.t), String.t) :: boolean
  defp syllables_is_word_subset?(syllables, word) do
    {:ok, regex} =
      syllables
      |> Enum.join(".*")
      |> Regex.compile
    Regex.match?(regex, String.downcase(word))
  end
end
