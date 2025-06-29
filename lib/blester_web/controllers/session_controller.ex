defmodule BlesterWeb.SessionController do
  use BlesterWeb, :controller

  def set_session(conn, %{"user_id" => user_id}) do
    conn
    |> put_session(:user_id, user_id)
    |> redirect(to: "/blog")
  end

  def logout(conn, _params) do
    conn
    |> clear_session()
    |> redirect(to: "/")
  end
end
