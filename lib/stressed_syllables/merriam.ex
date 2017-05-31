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
    |> HTTPoison.get(@user_agent, [hackney: [{:follow_redirect, true}]])
    |> handle_response(word)
  end

  defp word_url(word) do
    "#{@merriam_url}/dictionary/#{word}"
  end

  defp handle_response({:ok, %{status_code: 200, body: body}}, word) do
    Floki.find(body, ".word-attributes")
    |> Utils.reject_map(fn node -> word_from_node(word, node) end)
  end

  defp handle_response({_, %{status_code: 404, body: _body}}, _word) do
    :not_found
  end

  defp handle_response({_, %{status_code: code, body: body}}, word) do
    Logger.error "Error retrieving #{word}"
    Logger.error inspect [status_code: code, body: body]
    :error
  end

  defp text_in_node(node, selector) do
    Floki.find(node, selector)
    |> Floki.text
    |> String.trim
  end

  defp word_from_node(word, node) do
    type = text_in_node(node, ".main-attr")
    syllables = text_in_node(node, ".word-syllables")
    pronounciation = text_in_node(node, ".pr")
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
        # This is to deal with situations such as searching for the word "file"
        # which returns a result for filé, an entirely different word.
        if syllables_is_word_subset?(parsed, word) do
          %Word{ type: type,
            syllables: parsed,
            pronounciation: parse_pronounciation(pronounciation)
          }
        else
          nil
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
