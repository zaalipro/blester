defmodule BlesterWeb.SessionController do
  use BlesterWeb, :controller
  alias Blester.Accounts

  def set_session(conn, %{"user_id" => user_id}) do
    # Verify the user exists before setting session
    case Accounts.get_user(user_id) do
      {:ok, user} when not is_nil(user) ->
        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Welcome back, #{user.first_name}!")
        |> redirect(to: "/blog")
      _ ->
        conn
        |> put_flash(:error, "Invalid user session.")
        |> redirect(to: "/login")
    end
  end

  def logout(conn, _params) do
    user = conn.assigns[:current_user]

    conn
    |> clear_session()
    |> put_flash(:info, if(user, do: "Goodbye, #{user.first_name}!", else: "Logged out successfully."))
    |> redirect(to: "/")
  end
end
