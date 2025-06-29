defmodule BlesterWeb.Plugs.SetCurrentUser do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    # Try to get user_id from session first, then from cookies
    user_id = get_session(conn, :user_id) || get_cookie_user_id(conn)

    # Ensure user_id is in session for LiveViews to access
    conn = if user_id do
      put_session(conn, :user_id, user_id)
    else
      conn
    end

    assign(conn, :current_user_id, user_id)
  end

  defp get_cookie_user_id(conn) do
    case conn.cookies["user_id"] do
      nil -> nil
      user_id -> user_id
    end
  end
end
