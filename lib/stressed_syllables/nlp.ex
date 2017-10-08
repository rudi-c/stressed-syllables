defmodule StressedSyllables.NLP do
  use GenServer
  require Logger

  @script :nlp

  def start_link() do
    spacy_path = to_char_list(Application.app_dir(:stressed_syllables, "priv/spacy"))
    python_path = to_char_list(Application.app_dir(:stressed_syllables, "priv/spacy/.env/bin/python"))
    opts = [{:python_path, spacy_path}, {:python, python_path}]
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
    {time, _} = :timer.tc(fn ->
      :python.call(python_process, @script, :load_model, []) end)
    Logger.info "Loaded Spacy NLP model in #{time / 1000}ms"
    {:noreply, python_process}
  end

  def handle_call({:analyze_text, text}, _from, python_process) do
    {time, result} = :timer.tc(fn ->
      :python.call(python_process, @script, :analyze_text, [text]) end)

    Logger.info "Did NLP analysis on #{String.length(text)} chars in #{time / 1000}ms"

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
