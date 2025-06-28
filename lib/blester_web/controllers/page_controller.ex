defmodule BlesterWeb.PageController do
  use Phoenix.Controller, layouts: [html: {BlesterWeb.Layouts, :app}]
  import Plug.Conn
  import BlesterWeb.Gettext

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home)
  end
end
