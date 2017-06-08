defmodule StressedSyllables.Merriam do
  use GenServer
  require Logger

  @moduledoc """
  Load the Merriam-Webster page for a particular word and parses out
  the pronounciation and stressed syllables.
  """

  defmodule Word do
    defstruct pofspeech: "", syllables: [], pronounciation: []
  end

  @user_agent [ {"User-agent", "Elixir"}]
  @merriam_url "https://www.merriam-webster.com"
  @pronounciation_regex ~r/\\(.*)\\/

  def start_link() do
    GenServer.start_link(__MODULE__, {0, :queue.new}, name: __MODULE__)
  end

  def get_word(word) do
    GenServer.cast(__MODULE__, {:get_word, word, self()})
    receive do
      # TODO: Is it ever a problem if messages for the same word get mixed up?
      # (not if there's only one call to get_word per process...)
      {:finished, ^word, result} -> result
    end
  end

  def make_request(word, sender) do
    GenServer.cast(__MODULE__, {:make_request, word, sender})
  end

  def handle_cast({:get_word, word, sender}, {running_requests, queue}) when running_requests < 20 do
    make_request(word, sender)
    {:noreply, {running_requests + 1, queue}}
  end
  def handle_cast({:get_word, word, sender}, {running_requests, queue}) do
    {:noreply, {running_requests, :queue.in({word, sender}, queue)}}
  end

  def handle_cast({:make_request, word, sender}, {running_requests, queue}) do
    result =
      word_url(word)
      |> HTTPoison.get(@user_agent, [hackney: [{:follow_redirect, true}]])
      |> handle_response(word)
    send sender, {:finished, word, result}

    case :queue.out(queue) do
      {{:value, {next_word, next_from}}, next_queue} ->
        make_request(next_word, next_from)
        {:noreply, {running_requests, next_queue}}
      {:empty, next_queue} ->
        {:noreply, {running_requests - 1, next_queue}}
    end
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
        spacy_pofspeech = merriam_to_spacy(word, type)
        # This is to deal with situations such as searching for the word "file"
        # which returns a result for filé, an entirely different word.
        if syllables_is_word_subset?(parsed, word) do
          %Word{ pofspeech: spacy_pofspeech,
            syllables: parsed,
            pronounciation: parse_pronounciation(pronounciation)
          }
        else
          nil
        end
    end
  end

  def merriam_to_spacy(word, pofspeech) do
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
