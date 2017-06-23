defmodule StressedSyllables.ApiController do
  require Logger

  use StressedSyllables.Web, :controller

  def get_stress(conn, %{ "text" => text }) do
    if String.length(text) > 1000 do
      json put_status(conn, :bad_request), "input too large"
    else
      result = Utils.throttle(fn -> get_result(text) end, 2000)
      json conn, %{result: result}
    end
  end

  def get_result(text) do
    text
    |> StressedSyllables.Stressed.find_stress
    |> StressedSyllables.Formatter.print_for_web
  end
end
