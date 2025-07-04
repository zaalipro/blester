defmodule BlesterWeb.Plugs.SetCurrentUser do
  import Plug.Conn
  alias Blester.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)

    case user_id do
      nil ->
        conn
        |> assign(:current_user, nil)
        |> assign(:current_user_id, nil)
      user_id ->
        case Accounts.get_user(user_id) do
          {:ok, user} when not is_nil(user) ->
            conn
            |> assign(:current_user, user)
            |> assign(:current_user_id, user.id)
          _ ->
            # User not found, clear session
            conn
            |> clear_session()
            |> assign(:current_user, nil)
            |> assign(:current_user_id, nil)
        end
    end
  end
end
