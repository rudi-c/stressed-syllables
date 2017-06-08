defmodule StressedSyllables.Stressed do
  require Logger

  @moduledoc """
  Finds the words in a chunk of text and return all the stressed syllables it
  can find.
  """

  def find_stress(text, progress_bar \\ false) do
    String.trim(text) |> find_in_text(progress_bar)
  end

  defp find_in_text(text, progress_bar) do
    lines_of_words = StressedSyllables.NLP.analyze_text(text)

    words =
      lines_of_words
      |> Enum.map(fn words -> Enum.map(words, fn {word, _, _} -> word end) end)
      |> Enum.concat
      |> Enum.sort
      |> Enum.dedup

    mapper = if progress_bar do &Parallel.progress_pmap/2 else &Parallel.pmap/2 end
    processed_words_map =
      mapper.(words, fn word ->
        { word, StressedSyllables.Merriam.get_word word }
      end)
      |> Map.new

    word_results =
      lines_of_words
      |> Enum.map(fn pieces ->
        Enum.map(pieces, fn { word, start, pofspeech } ->
          { status, cases } =
            Map.fetch!(processed_words_map, word)
            |> filter_cases(pofspeech)
          if status == :no_pof do
            Logger.warn "No matching part of speech for '#{pofspeech}' for '#{word}'"
          end
          { start, String.length(word), cases }
        end)
      end)

    splitted_lines = String.split(text, "\n")
    Enum.zip(splitted_lines, word_results)
  end

  defp filter_cases(:not_found, _pofspeech) do
    {:ok, :not_found}
  end

  defp filter_cases(:error, _pofspeech) do
    {:ok, :not_found}
  end

  defp filter_cases([], _pofspeech) do
    {:ok, nil}
  end

  defp filter_cases(cases, pofspeech) do
    any_pofspeech_match =
      cases |> Enum.any?(&(&1.pofspeech == pofspeech))
    if any_pofspeech_match do
      result = cases
        |> Enum.filter(&(&1.pofspeech == pofspeech))
        |> collapse_cases
      {:ok, result}
    else
      {:no_pof, collapse_cases cases}
    end
  end

  # When possible, we want to return {:syllables, syllables, stressed_index}
  # Sometimes, we just return the phonetics directly {:phonetics, phonetics_list}
  # This happens if:
  # - For any reason, the syllables list are not all the same
  # - The syllables list does not match the pronounciation
  # - The pronunciation list does not have stressed syllables all at the same place
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
    index = Enum.find_index(pronounciation, &is_stressed?/1)
    if index == nil do
      Logger.error "No stressed syllable found"
      Logger.error inspect pronounciation
    end
    index
  end

  defp is_stressed?(phoneme) do
    String.starts_with?(phoneme, "ˈ")
  end
end
