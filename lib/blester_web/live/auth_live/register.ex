defmodule BlesterWeb.AuthLive.Register do
  use BlesterWeb, :live_view
  import BlesterWeb.LiveValidations
  alias Blester.Accounts

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]
    cart_count = if user_id, do: Accounts.get_cart_count(user_id), else: 0
    current_user = case user_id do
      nil -> nil
      id -> case Accounts.get_user(id) do
        {:ok, user} -> user
        _ -> nil
      end
    end

    {:ok, assign(socket,
      user: %{},
      errors: %{},
      current_user_id: user_id,
      current_user: current_user,
      cart_count: cart_count
    )}
  end

  @impl true
  def handle_event("register", %{"user" => user_params}, socket) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        {:noreply, add_flash_timer(socket, :info, "Account created successfully! Please log in.") |> redirect(to: "/login")}
      {:error, changeset} ->
        errors = format_errors(changeset.errors)
        {:noreply, assign(socket, errors: errors) |> add_flash_timer(:error, "Failed to create account")}
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

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div class="max-w-md w-full space-y-8">
        <div>
          <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Create your account
          </h2>
        </div>
        <form class="mt-8 space-y-6" phx-submit="register" phx-change="validate">
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
            </div>
            <div>
              <label for="first_name" class="sr-only">First name</label>
              <input
                id="first_name"
                name="user[first_name]"
                type="text"
                required
                class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="First name"
                value={@user["first_name"] || ""}
              />
            </div>
            <div>
              <label for="last_name" class="sr-only">Last name</label>
              <input
                id="last_name"
                name="user[last_name]"
                type="text"
                required
                class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="Last name"
                value={@user["last_name"] || ""}
              />
            </div>
            <div>
              <label for="country" class="sr-only">Country</label>
              <input
                id="country"
                name="user[country]"
                type="text"
                required
                class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="Country"
                value={@user["country"] || ""}
              />
            </div>
            <div>
              <label for="password" class="sr-only">Password</label>
              <input
                id="password"
                name="user[password]"
                type="password"
                required
                class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="Password"
                value={@user["password"] || ""}
              />
            </div>
            <div>
              <label for="password_confirmation" class="sr-only">Confirm password</label>
              <input
                id="password_confirmation"
                name="user[password_confirmation]"
                type="password"
                required
                class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="Confirm password"
                value={@user["password_confirmation"] || ""}
              />
            </div>
          </div>

          <div>
            <button
              type="submit"
              class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Create account
            </button>
          </div>

          <div class="text-center">
            <a href="/login" class="text-indigo-600 hover:text-indigo-500">
              Already have an account? Sign in
            </a>
          </div>
        </form>
      </div>
    </div>
    """
  end
end
