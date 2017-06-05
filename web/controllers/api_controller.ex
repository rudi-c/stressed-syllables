defmodule StressedSyllables.ApiController do
  require Logger

  use StressedSyllables.Web, :controller

  def get_stress(conn, %{ "text" => text }) do
    result =
      StressedSyllables.Stressed.find_stress(text)
      |> StressedSyllables.Formatter.print_for_web(text)
    json conn, %{result: result}
  end
end
