defmodule Parallel do
  @moduledoc """http://elixir-recipes.github.io/concurrency/parallel-map/"""

  def pmap(collection, func) do
    collection
    |> Enum.map(&(Task.async(fn -> func.(&1) end)))
    |> Enum.map(&Task.await/1)
  end
end
