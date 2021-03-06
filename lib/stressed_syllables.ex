defmodule StressedSyllables do
  use Application
  require Logger

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = if Utils.is_master?() do
      Logger.info "Started node #{Node.self()} as master"
      [
        # Start the Ecto repository
        # supervisor(StressedSyllables.Repo, []),
        # Start the endpoint when the application starts
        supervisor(StressedSyllablesWeb.Endpoint, []),
        # Start your own worker by calling: StressedSyllables.Worker.start_link(arg1, arg2, arg3)
        supervisor(StressedSyllables.NLP, []),
        supervisor(StressedSyllables.MerriamLoader, []),
        supervisor(StressedSyllables.WordCache, []),
        supervisor(StressedSyllables.NewWordCache, []),
        supervisor(StressedSyllables.LoadBalancer, []),
        supervisor(Task.Supervisor, [[name: StressedSyllables.RemoteTasks]])
      ]
    else
      Logger.info "Started node #{Node.self()} as replica"
      [
        supervisor(StressedSyllables.NLP, []),
        supervisor(StressedSyllables.MerriamLoader, []),
        supervisor(StressedSyllables.WordCache, []),
        supervisor(Task.Supervisor, [[name: StressedSyllables.RemoteTasks]])
      ]
    end

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: StressedSyllables.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    StressedSyllablesWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def find_stress(text) do
    String.trim(text)
    |> StressedSyllables.Stressed.find_stress(true)
    |> StressedSyllables.Formatter.print_for_terminal
  end

  def find_stress_in_file(filename) do
    File.read!(filename)
    |> find_stress
  end
end
