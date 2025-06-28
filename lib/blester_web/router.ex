defmodule BlesterWeb.Router do
  use BlesterWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BlesterWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BlesterWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/register", AuthController, :register
    post "/register", AuthController, :create_user
    get "/login", AuthController, :login
    post "/login", AuthController, :authenticate_user
    get "/logout", AuthController, :logout

    # Blog routes
    get "/blog", BlogController, :index
    get "/blog/new", BlogController, :new_post
    post "/blog", BlogController, :create_post
    get "/blog/:id", BlogController, :show_post
    get "/blog/:id/edit", BlogController, :edit_post
    post "/blog/:id/edit", BlogController, :update_post
    post "/blog/:id/delete", BlogController, :delete_post

    post "/blog/:post_id/comments", BlogController, :create_comment
    get "/blog/:post_id/comments/:comment_id/edit", BlogController, :edit_comment
    post "/blog/:post_id/comments/:comment_id/edit", BlogController, :update_comment
    post "/blog/:post_id/comments/:comment_id/delete", BlogController, :delete_comment
  end

  # Other scopes may use custom stacks.
  # scope "/api", BlesterWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: BlesterWeb.Telemetry
    end
  end

  defp fetch_current_user(conn, _opts) do
    user_id = get_session(conn, :user_id)
    assign(conn, :current_user_id, user_id)
  end
end
