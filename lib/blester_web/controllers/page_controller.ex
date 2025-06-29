defmodule BlesterWeb.PageController do
  use Phoenix.Controller, layouts: [html: {BlesterWeb.Layouts, :app}]
  import Plug.Conn

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, BlesterWeb.PageHTML, :home)
  end

  def logout(conn, _params) do
    conn
    |> clear_session()
    |> delete_resp_cookie("user_id")
    |> put_flash(:info, "You have been logged out.")
    |> redirect(to: "/")
  end

  def set_session(conn, %{"user_id" => user_id}) do
    conn
    |> put_session(:user_id, user_id)
    |> put_resp_cookie("user_id", user_id, sign: true, http_only: true, max_age: 60 * 60 * 24 * 30)
    |> redirect(to: "/")
  end

  def set_session(conn, _params) do
    conn
    |> put_flash(:error, "Invalid session setup")
    |> redirect(to: "/login")
  end
end
