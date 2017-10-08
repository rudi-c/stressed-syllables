defmodule StressedSyllables.PageControllerTest do
  use StressedSyllablesWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "English Stressed Syllables Finder"
  end
end
