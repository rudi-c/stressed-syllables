defmodule Parallel do
  @moduledoc """
  http://elixir-recipes.github.io/concurrency/parallel-map/
  """

  @total_bars 25

  def progress_bar(parent, count, total) do
    bars_count = round(count / total * @total_bars)
    IO.write("\r["
      <> String.duplicate("=", bars_count)
      <> String.duplicate(" ", @total_bars - bars_count)
      <> "] #{count} / #{total}")

    receive do
      :increment ->
        next = count + 1
        if next == total do
          send parent, :finished
          IO.write("\r")
        else
          progress_bar(parent, next, total)
        end
    end
  end

  # pmap with a progress bar
  def progress_pmap(collection, func) do
    total = length(collection)
    progress_bar = spawn(Parallel, :progress_bar, [self(), 0, total])

    result =
      collection
      |> Enum.map(&(Task.async(fn ->
          result = func.(&1)
          send progress_bar, :increment
          result
        end)))
      |> Enum.map(&Task.await/1)

    receive do
      :finished -> result
    end
  end

  def pmap(collection, func) do
    collection
    |> Enum.map(&(Task.async(fn -> func.(&1) end)))
    |> Enum.map(&Task.await/1)
  end
end
