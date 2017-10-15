defmodule StressedSyllables.MerriamLoader do
  use GenServer
  require Logger

  @moduledoc """
  Load the Merriam-Webster page for a particular word
  """

  @user_agent [ {"User-agent", "Elixir"}]
  @merriam_url "https://www.merriam-webster.com"

  def start_link() do
    GenServer.start_link(__MODULE__, {0, :queue.new}, name: __MODULE__)
  end

  def get_word(word) do
    cached_result = StressedSyllables.WordCache.get_word(word)
    if cached_result == nil do
      GenServer.cast(__MODULE__, {:get_word, word, self()})
      receive do
        # TODO: Is it ever a problem if messages for the same word get mixed up?
        # (not if there's only one call to get_word per process...)
        {:finished, ^word, result} ->
          StressedSyllables.WordCache.store_word(word, result)
          result
      end
    else
      cached_result
    end
  end

  def make_request(word, sender, attempts \\ 0) do
    GenServer.cast(__MODULE__, {:make_request, word, sender, attempts})
  end

  def handle_cast({:get_word, word, sender}, {running_requests, queue}) when running_requests < 20 do
    make_request(word, sender)
    {:noreply, {running_requests + 1, queue}}
  end
  def handle_cast({:get_word, word, sender}, {running_requests, queue}) do
    {:noreply, {running_requests, :queue.in({word, sender}, queue)}}
  end

  def handle_cast({:make_request, word, sender, attempts}, {running_requests, queue}) do
    result =
      word_url(word)
      |> HTTPoison.get(@user_agent, [hackney: [{:follow_redirect, true}]])
      |> handle_response(word)

    case result do
      :timeout when attempts < 3 ->
        Logger.warn "Request for '#{word}' timed out, attempt ##{attempts}..."
        make_request(word, sender, attempts + 1)
      result ->
        send sender, {:finished, word, result}

        case :queue.out(queue) do
          {{:value, {next_word, next_from}}, next_queue} ->
            make_request(next_word, next_from)
            {:noreply, {running_requests, next_queue}}
          {:empty, next_queue} ->
            {:noreply, {running_requests - 1, next_queue}}
        end
    end
  end

  defp word_url(word) do
    "#{@merriam_url}/dictionary/#{word}"
  end

  defp handle_response({:ok, %{status_code: 200, body: body}}, word) do
    Floki.find(body, ".word-attributes")
    |> Utils.reject_map(fn node -> word_from_node(word, node) end)
  end

  defp handle_response({:ok, %{status_code: 404, body: _body}}, _word) do
    :not_found
  end

  defp handle_response({:ok, %{status_code: code, body: body}}, word) do
    Logger.error "Error retrieving #{word}"
    Logger.error inspect [status_code: code, body: body]
    :error
  end

  defp handle_response({:error, %{reason: :timeout}}, word) do
    Logger.error "Timeout on retrieving #{word}"
    :timeout
  end

  defp handle_response({:error, %{reason: reason}}, word) do
    Logger.error "Error retrieving #{word} because #{reason}"
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
    StressedSyllables.MerriamWord.parse(word, type, syllables, pronounciation)
  end
end
