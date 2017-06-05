defmodule StressedSyllables.ApiController do
  require Logger

  use StressedSyllables.Web, :controller

  def get_stress(conn, %{ "text" => text }) do
    result = StressedSyllables.find_stress(text)
    Logger.info inspect result
    json conn, %{result: "TODO"}
  end
end
