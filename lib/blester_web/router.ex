defmodule BlesterWeb.Router do
  use BlesterWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BlesterWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug BlesterWeb.Plugs.SetCurrentUser
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BlesterWeb do
    pipe_through :browser

    get "/", PageController, :home
    delete "/logout", PageController, :logout
    get "/auth/set_session", PageController, :set_session

    # Auth LiveView routes
    live "/login", AuthLive.Login
    live "/register", AuthLive.Register

    # Blog LiveView routes
    live "/blog", BlogLive.Index
    live "/blog/new", BlogLive.New
    live "/blog/:id", BlogLive.Show
    live "/blog/:id/edit", BlogLive.Edit
    live "/blog/:id/comments/:comment_id/edit", BlogLive.EditComment
  end

  # Other scopes may use custom stacks.
  # scope "/api", BlesterWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:blester, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BlesterWeb.Telemetry
    end
  end
end
