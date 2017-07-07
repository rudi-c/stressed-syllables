defmodule StressedSyllables.LoadBalancer do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, 0, name: __MODULE__)
  end

  def get_next_node() do
    GenServer.call(__MODULE__, :get_next_node, :infinity)
  end

  def handle_call(:get_next_node, _from, node_index) do
    nodes = Node.list()
    cond do
      node_index > length nodes ->
        Logger.info "Load balancer reset, using node 0 (#{inspect self()})"
        {:reply, Node.self(), 0}
      node_index == 0 ->
        Logger.info "Load balancer, using node 0 (#{inspect self()})"
        {:reply, Node.self(), next_index(node_index, nodes)}
      true ->
        node = Enum.at(nodes, node_index - 1)
        Logger.info "Load balancer, using node #{node_index} (#{inspect node})"
        {:reply, node, next_index(node_index, nodes)}
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
