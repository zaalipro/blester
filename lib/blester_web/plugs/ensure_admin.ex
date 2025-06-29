defmodule BlesterWeb.Plugs.EnsureAdmin do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    user = conn.assigns[:current_user]

    case user do
      nil ->
        conn
        |> put_flash(:error, "You must be logged in to access this page.")
        |> redirect(to: "/login")
        |> halt()
      user ->
        if user.role == "admin" do
          conn
        else
          conn
          |> put_flash(:error, "You don't have permission to access this page.")
          |> redirect(to: "/")
          |> halt()
        end
    end
  end
end
