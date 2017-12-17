defmodule StressedSyllables.NewWordCache do
  use Amnesia
  use GenServer
  use WordDB
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state = %{}) do
    # Mnesia needs to be stopped in order to create the schema properly
    :stopped = Amnesia.stop()

    case Amnesia.Schema.create([node()]) do
      :ok ->
        Logger.info "Create Mnesia schema"
      {:error, {pid, {:already_exists, pid}}} ->
        Logger.info "Mnesia schema already exists - nothing to do"
    end

    :ok = Amnesia.start()

    case WordDB.WordInfo.create(disk: [node()]) do
      :ok ->
        Logger.info "Create DB"
      {:error, {:already_exists, WordDB.WordInfo}} ->
        Logger.info "DB already created - nothing to do"
    end

    :ok = WordDB.WordInfo.wait()
    {:ok, state}
  end

  def add(word, syllables, pronounciation) do
    Amnesia.transaction do
      %WordInfo{word: word, syllables: syllables, pronounciation: pronounciation}
      |> WordInfo.write
    end
  end

  def get(word) do
    Amnesia.transaction do WordInfo.read(word) end
  end
end