defmodule BlesterWeb.AuthLive.Login do
  use BlesterWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Log in")}
  end

  def handle_event("login", %{"user" => %{"email" => email, "password" => password}}, socket) do
    case Blester.Accounts.User.authenticate(email, password) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Welcome back!")
         |> redirect(to: "/")}

      {:error, :invalid_password} ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid email or password")
         |> assign(error_message: "Invalid email or password")}

      {:error, :user_not_found} ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid email or password")
         |> assign(error_message: "Invalid email or password")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="form-container">
      <h1 class="text-3xl font-bold text-center mb-2">Log in</h1>
      <p class="text-center text-gray-600 mb-8">Welcome back</p>

      <form phx-submit="login">
        <div class="form-group">
          <label for="email" class="form-label">Email</label>
          <input type="email" name="user[email]" id="email" required class="form-input" />
        </div>

        <div class="form-group">
          <label for="password" class="form-label">Password</label>
          <input type="password" name="user[password]" id="password" required class="form-input" />
        </div>

        <div class="form-group">
          <button type="submit" phx-disable-with="Signing in..." class="btn btn-primary w-full">
            Log in
          </button>
        </div>
      </form>

      <p class="text-center mt-6">
        Don't have an account? <a href="/register" class="text-blue-600 hover:text-blue-800 font-semibold">Register</a>
      </p>
    </div>
    """
  end
end
