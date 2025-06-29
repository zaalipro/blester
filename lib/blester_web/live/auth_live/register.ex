defmodule BlesterWeb.AuthLive.Register do
  use BlesterWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]
    cart_count = if user_id, do: Accounts.get_cart_count(user_id), else: 0
    case user_id do
      nil ->
        {:ok, assign(socket, form: %{}, errors: %{}, cart_count: cart_count)}
      user_id ->
        {:ok, push_navigate(socket, to: "/")}
    end
  end

  def handle_event("validate", params, socket) do
    form = to_form(params)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("register", %{"email" => email, "password" => password, "password_confirmation" => password_confirmation, "first_name" => first_name, "last_name" => last_name, "country" => country}, socket) do
    if password != password_confirmation do
      {:noreply,
       socket
       |> put_flash(:error, "Passwords do not match")
       |> assign(form: to_form(%{"email" => email, "password" => "", "password_confirmation" => "", "first_name" => first_name, "last_name" => last_name, "country" => country}))}
    else
      case Blester.Accounts.create_user(%{
        email: email,
        password: password,
        first_name: first_name,
        last_name: last_name,
        country: country
      }) do
        {:ok, user} ->
          {:noreply,
           socket
           |> put_flash(:info, "Account created successfully!")
           |> redirect(to: "/set_session?user_id=#{user.id}")}

        {:error, _changeset} ->
          {:noreply,
           socket
           |> put_flash(:error, "Registration failed")
           |> assign(form: to_form(%{"email" => email, "password" => "", "password_confirmation" => "", "first_name" => first_name, "last_name" => last_name, "country" => country}))}
      end
    end
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
                name="email"
                type="email"
                required
                class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-t-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="Email address"
                value={@form["email"].value}
              />
            </div>
            <div>
              <label for="first_name" class="sr-only">First name</label>
              <input
                id="first_name"
                name="first_name"
                type="text"
                required
                class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="First name"
                value={@form["first_name"].value}
              />
            </div>
            <div>
              <label for="last_name" class="sr-only">Last name</label>
              <input
                id="last_name"
                name="last_name"
                type="text"
                required
                class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="Last name"
                value={@form["last_name"].value}
              />
            </div>
            <div>
              <label for="country" class="sr-only">Country</label>
              <input
                id="country"
                name="country"
                type="text"
                required
                class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="Country"
                value={@form["country"].value}
              />
            </div>
            <div>
              <label for="password" class="sr-only">Password</label>
              <input
                id="password"
                name="password"
                type="password"
                required
                class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="Password"
                value={@form["password"].value}
              />
            </div>
            <div>
              <label for="password_confirmation" class="sr-only">Confirm password</label>
              <input
                id="password_confirmation"
                name="password_confirmation"
                type="password"
                required
                class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="Confirm password"
                value={@form["password_confirmation"].value}
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
