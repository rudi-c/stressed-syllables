defmodule StressedSyllables.Stressed do
  require Logger

  @moduledoc """
  Finds the words in a chunk of text and return all the stressed syllables it
  can find.
  """

  @word_splitter ~r/[a-zA-Z]+/

  def find_in_text(text) do
    Regex.scan(@word_splitter, text, return: :index)
    |> Parallel.pmap(fn [{start, len}] ->
      {start, len, String.slice(text, start, len) |> StressedSyllables.Merriam.get_word}
    end)
    |> Enum.map(fn {start, len, cases} -> {start, len, collapse_cases(cases)} end)
  end

  defp collapse_cases(:error) do
    :error
  end

  defp collapse_cases([]) do
    nil
  end

  defp collapse_cases(cases) do
    syllables_list = cases |> Enum.map(&(&1.syllables))
    pronounciations = cases |> Enum.map(&(&1.pronounciation))

    unless are_all_the_same(syllables_list) do
      Logger.error "Syllable lists not all the same"
      Logger.error inspect syllables_list
    end
    [syllables | _] = syllables_list

    # TODO: Handle multiple possibilities for stressed indices
    [stress_index | _] =
      pronounciations
      |> Enum.map(fn pronounciation ->
        if Kernel.length(pronounciation) == Kernel.length(syllables) do
          index = Enum.find_index(pronounciation, &is_stressed?/1)
          if index == nil do
            Logger.error "No stressed syllable found"
            Logger.error inspect pronounciation
          end
          index
        else
          nil
        end
      end)
      |> Enum.sort
      |> Enum.dedup

    {syllables, stress_index}
  end

  defp are_all_the_same([head | tail]) do
    Enum.all?(tail, fn x -> x == head end)
  end

  defp is_stressed?(phoneme) do
      String.starts_with?(phoneme, "ˈ")
  end
end
