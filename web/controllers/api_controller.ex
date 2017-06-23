defmodule StressedSyllables.ApiController do
  require Logger

  use StressedSyllables.Web, :controller

  def get_stress(conn, %{ "text" => text }) do
    if String.length(text) > 1000 do
      json put_status(conn, :bad_request), "input too large"
    else
      result =
        text
        |> StressedSyllables.Stressed.find_stress
        |> StressedSyllables.Formatter.print_for_web
      json conn, %{result: result}
    end
  end
end
