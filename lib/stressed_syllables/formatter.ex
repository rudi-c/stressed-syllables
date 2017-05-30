defmodule StressedSyllables.Formatter do
  @moduledoc """
  Prints stressed syllables in an easy-to-read format.
  """

  def print(words, text) do
    IO.puts inspect words

    split_into_sections_by_words(words, text)
    |> Enum.map(&print_section/1)

    IO.write "\n"
  end

  defp split_into_sections_by_words([word = {start, _, _} | tail], text) when start > 0 do
    {output, start_of_next} = _split_into_sections_by_words([word | tail], text)
    [ {String.slice(text, 0..start_of_next - 1), nil} | output ]
  end
  defp split_into_sections_by_words(words, text) do
    {output, _} = _split_into_sections_by_words(words, text)
    output
  end

  defp _split_into_sections_by_words([], text) do
    {[], String.length text}
  end
  defp _split_into_sections_by_words([word | tail], text) do
    {output, start_of_next} = _split_into_sections_by_words(tail, text)
    {start, _, info} = word
    {[ {String.slice(text, start..start_of_next - 1), info} | output ], start}
  end

  defp print_section({text, nil}) do
    IO.write text
  end
  defp print_section({text, {:phonetics, _phonetics}}) do
    IO.write text
  end
  defp print_section({text, {:syllables, syllables, stress_index}}) do
    {:ok, regex} =
      syllables
      |> Enum.with_index
      |> Enum.map(fn {syllable, index} ->
          if index == stress_index do
            "(?<stressed>#{syllable})"
          else
            syllable
          end
        end)
      |> Enum.join(".*")
      |> Regex.compile

    # Will only capture the location of the stressed syllable
    [{start, len}] = Regex.run(regex, text, return: :index, capture: :all_names)

    IO.write String.slice(text, 0, start)
    IO.write "\e[4m"
    IO.write String.slice(text, start, len)
    IO.write "\e[24m"
    IO.write String.slice(text, start + len, String.length(text) - (start + len))
  end
end
