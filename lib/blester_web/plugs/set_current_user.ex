defmodule BlesterWeb.Plugs.SetCurrentUser do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)
    assign(conn, :current_user_id, user_id)
  end
end
