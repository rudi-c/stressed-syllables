defmodule StressedSyllables.WordCache do
  use GenServer
  require Logger

  @moduledoc """
  Distributed cache of Merriam dictionary words with a master and
  read-only replicas.
  """

  @cache "var/cache"

  def get_word(word) do
    GenServer.call(__MODULE__, {:get_word, type_token(), word})
  end

  def store_word(word, result) do
    Logger.info "Storing word \"#{inspect word}\""
    GenServer.cast(__MODULE__, {:store_word, type_token(), word, result})
  end

  def update_cache(word, result) do
    Logger.info "Updating cache \"#{inspect word}\""
    GenServer.cast(__MODULE__, {:update_cache, word, result})
  end

  def send_all() do
    Logger.info "Sending everything"
    GenServer.cast(__MODULE__, :send_all)
    Logger.info "Done sending everything"
  end

  def start_link() do
    if Utils.is_master?() do
      case Node.list do
        [] -> Logger.info "Starting master cache - found no replica"
        [_replica] -> Logger.info "Starting master cache - found replica"
      end

      if File.exists?(@cache) do
        ret = GenServer.start_link(__MODULE__, {read_cache(), open_cache()}, name: __MODULE__)
        send_all()
        ret
      else
        init_cache()
        GenServer.start_link(__MODULE__, {%{}, open_cache()}, name: __MODULE__)
      end
    else
      case Node.list do
        [] -> Logger.info "Starting replica cache - found no master"
        [_master] -> Logger.info "Starting replica cache - found master"
      end

      ret = GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

      call_on_master(:send_all, [])

      ret
    end
  end

  def handle_call({:get_word, :master, word}, _from, {cache, file}) do
    {:reply, cache[word], {cache, file}}
  end

  def handle_call({:get_word, :replica, word}, _from, cache) do
    {:reply, cache[word], cache}
  end

  def handle_cast({:store_word, :master, word, result}, {cache, file}) do
    persist_word(file, word, result)
    # Send update to replica
    call_on_replica(:update_cache, [word, result])
    {:noreply, {Map.put(cache, word, result), file}}
  end

  def handle_cast({:store_word, :replica, word, result}, cache) do
    # Send update to master
    call_on_master(:store_word, [word, result])
    {:noreply, cache}
  end

  def handle_cast({:update_cache, word, result}, cache) do
    {:noreply, Map.put(cache, word, result)}
  end

  def handle_cast(:send_all, {cache, file}) do
    Enum.each(cache, fn {word, result} ->
      call_on_replica(:store_word, [word, result])
    end)
    {:noreply, {cache, file}}
  end

  defp call_on_master(function, args) do
    case Node.list() do
      [] -> :ok
      [master] ->
        Task.Supervisor.async({StressedSyllables.RemoteTasks, master},
                               StressedSyllables.WordCache, function, args)
    end
  end

  defp call_on_replica(function, args) do
    case Node.list() do
      [] -> :ok
      [replica] ->
        Task.Supervisor.async({StressedSyllables.RemoteTasks, replica},
                               StressedSyllables.WordCache, function, args)
    end
  end

  defp type_token() do
    if Utils.is_master?() do
      :master
    else
      :replica
    end
  end

  defp open_cache() do
    File.open!(@cache, [:append, :utf8])
  end

  defp init_cache() do
    File.mkdir(Path.dirname(@cache))
    File.touch!(@cache)
  end

  defp persist_word(file, word, result) do
    IO.puts(file, to_string(Poison.encode!(%{"word" => word, "result" => result})))
  end

  defp read_cache() do
    File.stream!(@cache)
    |> Enum.reduce(%{}, fn (line, acc) ->
      decoded = Poison.decode!(line, as: %{"result" => [%StressedSyllables.MerriamWord.Word{}]})
      case decoded do
        %{"word" => word, "result" => "not_found"} -> Map.put(acc, word, :not_found)
        %{"word" => word, "result" => result} -> Map.put(acc, word, result)
      end
    end)
  end
end
