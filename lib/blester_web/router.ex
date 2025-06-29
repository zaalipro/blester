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

  # Public routes (no authentication required)
  scope "/", BlesterWeb do
    pipe_through :browser

    live "/", PageLive.Home
    live "/login", AuthLive.Login
    live "/register", AuthLive.Register
    get "/set_session", SessionController, :set_session
    get "/logout", SessionController, :logout
    live "/blog", BlogLive.Index
    live "/blog/:id", BlogLive.Show
    live "/shop", ShopLive.Index
    live "/shop/:id", ShopLive.Show
  end

  # Protected routes (authentication required)
  scope "/", BlesterWeb do
    pipe_through [:browser, BlesterWeb.Plugs.AuthenticateUser]

    live "/blog/new", BlogLive.New
    live "/blog/:id/edit", BlogLive.Edit
    live "/blog/:id/comments/:comment_id/edit", BlogLive.EditComment
    live "/cart", ShopLive.Cart
    live "/checkout", ShopLive.Checkout
  end

  # Admin routes (admin role required)
  scope "/admin", BlesterWeb do
    pipe_through [:browser, BlesterWeb.Plugs.AuthenticateUser, BlesterWeb.Plugs.EnsureAdmin]

    live "/dashboard", AdminLive.Dashboard
    live "/products", AdminLive.Products
    live "/products/new", AdminLive.Products.New
    live "/products/:id/edit", AdminLive.Products.Edit
    live "/orders", AdminLive.Orders
    live "/orders/:id", AdminLive.Orders.Show
    live "/users", AdminLive.Users
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
