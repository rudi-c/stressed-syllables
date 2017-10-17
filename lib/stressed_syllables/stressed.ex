defmodule StressedSyllables.Stressed do
  require Logger

  alias StressedSyllables.MerriamWord.Word
  alias StressedSyllables.NLP.WordInfo

  @moduledoc """
  Finds the words in a chunk of text and return all the stressed syllables it
  can find.
  """

  defmodule WordStressData do
    defstruct start: -1, length: -1, stress_information: %{}
  end

  @type stress_information :: {:syllables, list(String.t), integer}
                            | {:phonetics, list(String.t)}
  @type processed_words_map :: %{required(String.t) => list(%Word{})}

  def find_stress(text, progress_bar \\ false) do
    String.trim(text) |> find_in_text(progress_bar)
  end

  @spec find_in_text(String.t, boolean) :: list({String.t, list(%WordStressData{})})
  defp find_in_text(text, progress_bar) do
    lines_of_words = StressedSyllables.NLP.analyze_text(text)

    mapper = if progress_bar do &Parallel.progress_pmap/2 else &Parallel.pmap/2 end
    processed_words_map =
      lines_of_words
      |> get_unique_words
      |> mapper.(fn word -> { word, StressedSyllables.MerriamLoader.get_word word } end)
      |> Map.new

    word_results =
      lines_of_words
      |> Enum.map(fn line -> Enum.map(line, fn word_info ->
        get_stress_information(word_info, processed_words_map) end)
      end)

    lines = String.split(text, "\n")
    Enum.zip(lines, word_results)
  end

  @spec get_unique_words(list(list(%WordInfo{}))) :: list(String.t)
  defp get_unique_words(lines_of_words) do
    lines_of_words
    |> Enum.map(fn words -> Enum.map(words, fn word_info -> word_info.word end) end)
    |> Enum.concat
    |> Enum.sort
    |> Enum.dedup
  end

  @spec get_stress_information(%WordInfo{}, processed_words_map) :: %WordStressData{}
  def get_stress_information(word_info, processed_words_map) do
    cases =
      Map.fetch!(processed_words_map, word_info.word)
      |> filter_cases(word_info)
    %WordStressData{
      start: word_info.index,
      length: String.length(word_info.word),
      stress_information: cases
    }
  end

  # @spec filter_cases(:not_found | :error, list())
  defp filter_cases(:not_found, word_info) do
    Logger.debug "Word '#{word_info.word}' not found"
    :word_not_found
  end

  defp filter_cases(:error, word_info) do
    Logger.debug "Error encountered getting '#{word_info.word}'"
    :word_not_found
  end

  defp filter_cases([], word_info) do
    Logger.debug "Word '#{word_info.word}' has no cases"
    :no_case
  end

  defp filter_cases(cases, word_info) do
    any_pofspeech_match =
      cases |> Enum.any?(&(&1.pofspeech == word_info.pofspeech))
    cond do
      any_pofspeech_match ->
        cases
          |> Enum.filter(&(&1.pofspeech == word_info.pofspeech))
          |> collapse_cases
      use_verb_fallback(cases, word_info) ->
        Logger.warn "Using verb fallback for '#{word_info.word}'"
        cases
          |> Enum.filter(&(&1.pofspeech == "VERB"))
          |> collapse_cases
      true ->
        Logger.warn "No matching part of speech for '#{word_info.pofspeech}' for '#{word_info.word}'"
        collapse_cases cases
    end
  end

  defp use_verb_fallback(_cases, word_info) do
    word_info.pofspeech == "ADJ"
  end

  # When possible, we want to return {:syllables, syllables, stressed_index}
  # Sometimes, we just return the phonetics directly {:phonetics, phonetics_list}
  # This happens if:
  # - For any reason, the syllables list are not all the same
  # - The syllables list does not match the pronounciation
  # - The pronunciation list does not have stressed syllables all at the same place
  @spec collapse_cases(list(%Word{})) :: stress_information
  defp collapse_cases(cases) do
    syllables_list = cases |> Enum.map(&(&1.syllables))
    pronounciations =
      cases
      |> Enum.map(&(&1.pronounciation))
      |> Enum.sort |> Enum.dedup

    if not are_all_the_same(syllables_list) do
      # Logger.error "Syllable lists not all the same"
      # Logger.error inspect syllables_list
      {:phonetics, pronounciations}
    else
      [syllables | _] = syllables_list
      syllables_count = length(syllables)
      if Enum.any?(pronounciations, fn p -> length(p) != syllables_count end) do
        {:phonetics, pronounciations}
      else
        stress_indices =
          pronounciations
          |> Enum.map(&find_stress_index/1)
          |> Enum.sort |> Enum.dedup

        case stress_indices do
          [index] -> {:syllables, syllables, index}
          _ -> {:phonetics, pronounciations}
        end
      end
    end
  end

  defp are_all_the_same([head | tail]) do
    Enum.all?(tail, fn x -> x == head end)
  end

  defp find_stress_index(pronounciation) do
    index = Enum.find_index(pronounciation, &is_primary_stress?/1)
    if index == nil do
      index = Enum.find_index(pronounciation, &is_secondary_stress?/1)
      if index == nil do
        Logger.warn "No stressed syllable found"
        Logger.warn inspect pronounciation
      end
      index
    else
      index
    end
  end

  defp is_primary_stress?(phoneme) do
    String.starts_with?(phoneme, "ˈ")
  end

  defp is_secondary_stress?(phoneme) do
    String.starts_with?(phoneme, "ˌ")
  end
end
