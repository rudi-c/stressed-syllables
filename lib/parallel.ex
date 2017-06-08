defmodule Parallel do
  @moduledoc """
  http://elixir-recipes.github.io/concurrency/parallel-map/
  """

  # pmap with a progress bar
  def progress_pmap(collection, func, timeout \\ 15000) do
    total = length(collection)
    progress_bar = ProgressBar.start_bar(total)
    result =
      collection
      |> Enum.map(&(Task.async(fn ->
          result = func.(&1)
          ProgressBar.increment(progress_bar)
          result
        end)))
      |> Enum.map(fn task -> Task.await(task, timeout) end)

    ProgressBar.await()
    result
  end

  def pmap(collection, func, timeout \\ 15000) do
    collection
    |> Enum.map(&(Task.async(fn -> func.(&1) end)))
    |> Enum.map(fn task -> Task.await(task, timeout) end)
  end
end
