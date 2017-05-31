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
end
