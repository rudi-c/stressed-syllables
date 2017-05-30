defmodule StressedSyllables.Merriam do
  require Logger

  @moduledoc """
  Load the Merriam-Webster page for a particular word and parses out
  the pronounciation and stressed syllables.
  """

  defmodule Word do
    defstruct type: "", syllables: [], pronounciation: []
  end

  @user_agent [ {"User-agent", "Elixir"}]
  @merriam_url "https://www.merriam-webster.com"
  @pronounciation_regex ~r/\\(.*)\\/

  def get_word(word) do
    word_url(word)
    |> HTTPoison.get(@user_agent)
    |> handle_response
  end

  defp word_url(word) do
    "#{@merriam_url}/dictionary/#{word}"
  end

  defp handle_response({:ok, %{status_code: 200, body: body}}) do
    Floki.find(body, ".word-attributes")
    |> Enum.map(fn node ->
      {
        text_in_node(node, ".main-attr"),
        text_in_node(node, ".word-syllables"),
        text_in_node(node, ".pr")
      }
    end)
    |> Enum.filter_map(
      fn {_, syllables, pronounciation} ->
        Regex.match?(@pronounciation_regex, pronounciation) &&
          not String.contains?(pronounciation, "same as") &&
          String.length(syllables) > 0
      end,
      fn {type, syllables, pronounciation} ->
        %Word{ type: type,
          syllables: parse_syllables(syllables),
          pronounciation: parse_pronounciation(pronounciation)
        }
      end)
  end

  defp handle_response({_, %{status_code: _, body: body}}) do
    Logger.error body
    :error
  end

  defp text_in_node(node, selector) do
    Floki.find(node, selector)
    |> Floki.text
    |> String.trim
  end

  defp parse_syllables(syllables) do
    String.split(syllables, "·")
  end

  defp parse_pronounciation(str) do
    [_, pronounciation] = Regex.run(@pronounciation_regex, str)
    [first | _ ] = String.split(pronounciation, [",", " also "])
    String.split(first, "-")
  end
end
