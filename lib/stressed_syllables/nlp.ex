defmodule StressedSyllables.NLP do
  use GenServer
  require Logger

  @path Path.expand("lib/spacy")
  @script :nlp

  def start_link() do
    opts = [{:python_path, to_char_list(@path)}]
    {:ok, python_process} = :python.start(opts)
    res = GenServer.start_link(__MODULE__, python_process, name: __MODULE__)
    GenServer.cast __MODULE__, :load_model
    res
  end

  def analyze_text(text) do
    GenServer.call __MODULE__, {:analyze_text, text}
  end

  def handle_cast(:load_model, python_process) do
    Logger.info "Loading Spacy NLP model..."
    :python.call(python_process, @script, :load_model, [])
    Logger.info "Loaded Spacy NLP model..."
    {:noreply, python_process}
  end

  def handle_call({:analyze_text, text}, _from, python_process) do
    result = :python.call(python_process, @script, :analyze_text, [text])
    # Erlang returns char lists, want (unicode) strings instead
    elixir_result =
      result
      |> Enum.map(fn line -> Enum.map(line, fn { word, idx, pofspeech } ->
          { to_string(word), idx, to_string(pofspeech) }
        end)
      end)
    {:reply, elixir_result, python_process}
  end
end
