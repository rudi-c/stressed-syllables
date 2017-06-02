defmodule StressedSyllables.PageController do
  use StressedSyllables.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
