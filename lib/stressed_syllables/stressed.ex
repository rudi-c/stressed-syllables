defmodule StressedSyllables.Stressed do
  require Logger

  @moduledoc """
  Finds the words in a chunk of text and return all the stressed syllables it
  can find.
  """

  @word_splitter ~r/[a-zA-Z]+/

  def find_in_text(text) do
    Regex.scan(@word_splitter, text, return: :index)
    |> Parallel.progress_pmap(fn [{start, len}] ->
      {start, len, String.slice(text, start, len) |> StressedSyllables.Merriam.get_word}
    end)
    |> Enum.map(fn {start, len, cases} -> {start, len, collapse_cases(cases)} end)
  end

  defp collapse_cases(:error) do
    nil
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
