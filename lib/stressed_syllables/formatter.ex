defmodule StressedSyllables.Formatter do
  @moduledoc """
  Prints stressed syllables in an easy-to-read format.
  """

  @bold "\e[4m"
  @unbold "\e[24m"

  def print(words, text) do
    IO.puts inspect Enum.chunk(String.codepoints(text), 10, 10, [])
    IO.puts inspect words

    split_into_sections_by_words(words, text)
    |> Enum.map(fn section -> {section, section_length(section)} end)
    |> word_wrap(78)
    |> Enum.each(&print_row/1)
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

  defp print_row(row) do
    IO.write "> "
    Enum.each(row, fn {section = {text, _}, len} ->
      # Note that I can't use pad_trailing here because the terminal escape
      # characters will get counted in the string length
      str = with_n_spaces(format_section(section), len - String.length(text))
      IO.write str
    end)
    IO.write("\n")

    max_options =
      row
      |> Enum.map(fn {{_text, info}, _} -> phonetics_count(info) end)
      |> Enum.max

    Enum.each(Utils.range(0, max_options), fn n ->
      # To align with the "> "
      IO.write "  "

      Enum.each(row, fn {section, len} ->
        phonetic = nth_phonetic(section, n)

        output =
          phonetic
          |> Enum.map(&format_phoneme/1)
          |> Enum.join("-")

        IO.write with_n_spaces(output, len - phonetic_length(phonetic))
      end)

      IO.write("\n")
    end)
  end

  defp format_section({text, nil}) do
    text
  end
  defp format_section({text, {:phonetics, _phonetics}}) do
    text
  end
  defp format_section({text, {:syllables, syllables, stress_index}}) do
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
    [{start, len}] = Regex.run(regex, String.downcase(text), return: :index, capture: :all_names)

    # TODO: Support secondary stress
    String.slice(text, 0, start)
    <> @bold
    <> String.slice(text, start, len)
    <> @unbold
    <> String.slice(text, start + len, String.length(text) - (start + len))
  end

  defp nth_phonetic({_text, nil}, _n) do
    []
  end
  defp nth_phonetic({_text, {:phonetics, phonetics}}, n) do
    Enum.at(phonetics, n, [])
  end
  defp nth_phonetic({_text, {:syllables, _, _}}, _n) do
    []
  end

  defp phonetics_count(nil) do
    0
  end
  defp phonetics_count({:phonetics, phonetics}) do
    length(phonetics)
  end
  defp phonetics_count({:syllables, _, _}) do
    0
  end

  defp section_length({text, {:phonetics, phonetics}}) do
    len =
      phonetics
      |> Enum.map(&phonetic_length/1)
      |> Enum.max
    # Need to add one because we'll add a whitespace after the phonetic
    max(String.length(text), len + 1)
  end
  defp section_length({text, _}) do
    String.length text
  end

  defp phonetic_length([]) do
    0
  end
  defp phonetic_length(phonetic) do
    # Count the number of codepoints instead of the number of graphemes because
    # sometimes the terminal doesn't always combine codepoints and ends up using
    # two monospace characters. So to be safe, count codepoints, even if it leads
    # to too much whitespace padding.
    phonetic_chars_len =
      phonetic
      |> Enum.map(fn phoneme ->
        remove_stress_marker(phoneme) |> String.codepoints |> length
      end)
      |> Enum.sum
    dashes_len = length(phonetic) - 1 # number of "-" to add in-between
    phonetic_chars_len + dashes_len # add +1 for an extra whitespace
  end

  # Given a list of {section, section_length}, return a list of lists of section
  # such that they can be printed within <width> characters
  defp word_wrap(sections, width) do
    word_wrap(sections, width, 0, [], [])
    |> Enum.reverse
  end
  defp word_wrap([], _max_width, _current_width, current_row, rows) do
    [ Enum.reverse(current_row) | rows ]
  end
  defp word_wrap([{section, len} | tail],
                 max_width, current_width, current_row, rows)
  when len + current_width > max_width do
    # Section goes on the next line
    word_wrap(tail, max_width, len,
              [{section, len}], [ Enum.reverse(current_row) | rows ])
  end
  defp word_wrap([{section, len} | tail],
                 max_width, current_width, current_row, rows)
  do
    # Section goes on the current line
    word_wrap(tail, max_width, current_width + len,
              [{section, len} | current_row], rows)
  end

  defp format_phoneme(phoneme) do
    without_stress = remove_stress_marker(phoneme)
    if String.starts_with?(phoneme, "ˈ") do
      @bold <> without_stress <> @unbold
    else
      without_stress
    end
  end

  defp remove_stress_marker(phoneme) do
    String.replace(phoneme, ~r/(ˈ|ˌ)/, "")
  end

  def with_n_spaces(str, n) do
    str <> String.duplicate(" ", n)
  end
end
