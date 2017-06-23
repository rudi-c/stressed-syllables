defmodule StressedSyllables.WordCache do
  use GenServer
  require Logger

  @moduledoc """
  Cache of Merriam dictionary words
  """

  def get_word(word) do
    GenServer.call(__MODULE__, {:get_word, word})
  end

  def store_word(word, result) do
    GenServer.cast(__MODULE__, {:store_word, word, result})
  end

  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def handle_call({:get_word, word}, _from, cache) do
    {:reply, cache[word], cache}
  end

  def handle_cast({:store_word, word, result}, cache) do
    {:noreply, Map.put(cache, word, result)}
  end
end
