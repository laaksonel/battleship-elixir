defmodule BattleshipInterfaceWeb.PageController do
  alias BattleshipEngine.GameSupervisor
  use BattleshipInterfaceWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def test(conn, %{"name" => name}) do
    {:ok, _pid} = GameSupervisor.start_game(name)
    conn
    |> put_flash(:info, "You entered the name " <> name)
    |> render(:home)
  end
end
