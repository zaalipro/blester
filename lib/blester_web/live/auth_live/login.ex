defmodule BlesterWeb.AuthLive.Login do
  use BlesterWeb, :live_view
  import BlesterWeb.LiveValidations
  alias Blester.Accounts

  @impl true
  def mount(_params, session, socket) do
    user_id = session[:user_id]
    cart_count = if user_id, do: Accounts.get_cart_count(user_id), else: 0
    current_user = case user_id do
      nil -> nil
      id -> case Accounts.get_user(id) do
        {:ok, user} -> user
        _ -> nil
      end
    end

    # If user is already logged in, redirect to blog
    case user_id do
      nil ->
        {:ok, assign(socket,
          user: %{},
          errors: %{},
          current_user_id: user_id,
          current_user: current_user,
          cart_count: cart_count
        )}
      _user_id ->
        {:ok, push_navigate(socket, to: "/blog")}
    end
  end

  @impl true
  def handle_event("login", %{"user" => user_params}, socket) do
    case Accounts.authenticate_user(user_params["email"], user_params["password"]) do
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Logged in successfully! Welcome back, #{user.first_name}.")
         |> redirect(to: "/set_session?user_id=#{user.id}")}
      {:error, _} ->
        {:noreply,
         socket
         |> assign(errors: %{email: "Invalid email or password"})
         |> put_flash(:error, "Invalid email or password. Please try again.")}
    end
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    errors = validate_user(user_params)
    {:noreply, assign(socket, user: user_params, errors: errors)}
  end

  @impl true
  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div class="max-w-md w-full space-y-8">
        <div>
          <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Sign in to your account
          </h2>
        </div>
        <form class="mt-8 space-y-6" phx-submit="login" phx-change="validate">
          <div class="rounded-md shadow-sm -space-y-px">
            <div>
              <label for="email" class="sr-only">Email address</label>
              <input
                id="email"
                name="user[email]"
                type="email"
                required
                class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-t-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="Email address"
                value={@user["email"] || ""}
              />
              <%= if @errors[:email] do %>
                <p class="mt-1 text-sm text-red-600"><%= @errors[:email] %></p>
              <% end %>
            </div>
            <div>
              <label for="password" class="sr-only">Password</label>
              <input
                id="password"
                name="user[password]"
                type="password"
                required
                class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="Password"
                value={@user["password"] || ""}
              />
              <%= if @errors[:password] do %>
                <p class="mt-1 text-sm text-red-600"><%= @errors[:password] %></p>
              <% end %>
            </div>
          </div>

          <div>
            <button
              type="submit"
              class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Sign in
            </button>
          </div>

          <div class="text-center">
            <p class="text-sm text-gray-600">
              Don't have an account?
              <a href="/register" class="font-medium text-indigo-600 hover:text-indigo-500">
                Sign up
              </a>
            </p>
          </div>
        </form>
      </div>
    </div>
    """
  end
end
