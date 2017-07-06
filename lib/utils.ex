defmodule Utils do
  # TODO: This could be made more efficient by doing only one pass
  def reject_map(enumerable, mapper) do
    enumerable
    |> Enum.map(mapper)
    |> Enum.filter(fn val -> val != nil end)
  end

  # This exists because Elixir ranges can't be empty, which means you
  # have to special case the empty case all the time
  def range(start, finish) do
    if start == finish do
      []
    else
      start..finish-1
    end
  end

  # Make the execution time of thunk take at least `ms` milliseconds
  def throttle(thunk, ms) do
    {time, result} = :timer.tc(thunk)
    time_in_ms = round(time / 1000)
    if time_in_ms < ms do
      :ok = :timer.sleep(ms - time_in_ms)
    end
    result
  end

  def is_master?() do
    System.get_env("MASTER") == "true"
  end
end
