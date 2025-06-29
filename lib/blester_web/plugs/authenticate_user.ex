defmodule BlesterWeb.Plugs.AuthenticateUser do
  import Plug.Conn
  import Phoenix.Controller
  alias Blester.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)

    case user_id do
      nil ->
        conn
        |> put_flash(:error, "You must be logged in to access this page.")
        |> redirect(to: "/login")
        |> halt()
      user_id ->
        case Accounts.get_user(user_id) do
          {:ok, user} when not is_nil(user) ->
            conn
            |> assign(:current_user, user)
            |> assign(:current_user_id, user.id)
          _ ->
            conn
            |> clear_session()
            |> put_flash(:error, "Your session has expired. Please log in again.")
            |> redirect(to: "/login")
            |> halt()
        end
    end
  end
end
