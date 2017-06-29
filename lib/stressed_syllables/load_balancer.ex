defmodule StressedSyllables.LoadBalancer do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, 0, name: __MODULE__)
  end

  def find_stress(text) do
    GenServer.call(__MODULE__, {:find_stress, text}, :infinity)
  end

  def handle_call({:find_stress, text}, _from, next_node_index) do
    nodes = Node.list()
    cond do
      next_node_index > length nodes ->
        Logger.info "Load balancer reset, using node 0 (#{inspect self()})"
        result = StressedSyllables.Stressed.find_stress(text)
        {:reply, result, 0}
      next_node_index == 0 ->
        Logger.info "Load balancer, using node 0 (#{inspect self()})"
        result = StressedSyllables.Stressed.find_stress(text)
        {:reply, result, next_index(next_node_index, nodes)}
      true ->
        node = Enum.at(nodes, next_node_index - 1)
        Logger.info "Load balancer, using node #{next_node_index} (#{inspect node})"
        result =
          Task.Supervisor.async({StressedSyllables.RemoteTasks, node},
                                StressedSyllables.Stressed, :find_stress, [text])
          |> Task.await(:infinity)
        {:reply, result, next_index(next_node_index, nodes)}
    end
  end

  def next_index(index, nodes) do
    if index < length(nodes) do
      index + 1
    else
      0
    end
  end
end
