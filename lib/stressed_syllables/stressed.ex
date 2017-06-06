defmodule StressedSyllables.Stressed do
  require Logger

  @moduledoc """
  Finds the words in a chunk of text and return all the stressed syllables it
  can find.
  """

  @word_splitter ~r/[a-zA-Z]+/

  def find_stress(text, progress_bar \\ false) do
    String.trim(text) |> find_in_text(progress_bar)
  end

  defp find_in_text(text, progress_bar) do
    splitted_lines =
      String.split(text, "\n")
      |> Enum.map(fn line ->
        results =
          Regex.scan(@word_splitter, line, return: :index)
          |> Enum.map(fn [result] -> result end)
        {line, results}
      end)

    words =
      splitted_lines
      |> Enum.map(fn { line, pieces } ->
        Enum.map(pieces, fn {start, len} -> String.slice(line, start, len) end)
      end)
      |> Enum.concat
      |> Enum.sort
      |> Enum.dedup

    mapper = if progress_bar do &Parallel.progress_pmap/2 else &Parallel.pmap/2 end
    processed_words_map =
      mapper.(words, fn word ->
        { word, word |> StressedSyllables.Merriam.get_word |> collapse_cases }
      end)
      |> Map.new

    splitted_lines
    |> Enum.map(fn { line, pieces } ->
      processed_pieces =
        Enum.map(pieces, fn { start, len } ->
          word = String.slice(line, start, len)
          { start, len, Map.fetch!(processed_words_map, word) }
        end)
      { line, processed_pieces }
    end)
  end

  defp collapse_cases(:not_found) do
    :not_found
  end

  defp collapse_cases(:error) do
    :not_found
  end

  defp collapse_cases([]) do
    nil
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
