defmodule Utils do
  # TODO: This could be made more efficient by doing only one pass
  def reject_map(enumerable, mapper) do
    enumerable
    |> Enum.map(mapper)
    |> Enum.filter(fn val -> val != nil end)
  end
end
