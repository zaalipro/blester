defmodule BlesterWeb.AuthLive.Login do
  use BlesterWeb, :live_view

  alias Blester.Accounts

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"] || session[:user_id]
    {:ok,
     socket
     |> assign(current_user_id: user_id)
     |> assign(:page_title, "Log in")
     |> assign(:user, %{email: "", password: ""})
     |> assign(:errors, [])}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case authenticate_user(user_params) do
      {:ok, user} ->
        # Redirect to controller action to set session
        {:noreply,
         socket
         |> put_flash(:info, "Welcome back!")
         |> push_navigate(to: "/auth/set_session?user_id=#{user.id}")}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid email or password")
         |> assign(user: user_params)
         |> assign(errors: [reason])}
    end
  end

  @impl true
  def handle_event("save", params, socket) do
    # Handle the case where params come directly without the "user" wrapper
    user_params = %{
      "email" => params["email"] || "",
      "password" => params["password"] || ""
    }

    case authenticate_user(user_params) do
      {:ok, user} ->
        # Redirect to controller action to set session
        {:noreply,
         socket
         |> put_flash(:info, "Welcome back!")
         |> push_navigate(to: "/auth/set_session?user_id=#{user.id}")}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid email or password")
         |> assign(user: user_params)
         |> assign(errors: [reason])}
    end
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    {:noreply, assign(socket, user: user_params)}
  end

  @impl true
  def handle_event("validate", params, socket) do
    # Handle individual field validation
    current_user = socket.assigns.user

    # Update only the field that changed, preserving all others
    user_params = cond do
      Map.has_key?(params, "email") ->
        Map.put(current_user, "email", params["email"])
      Map.has_key?(params, "password") ->
        Map.put(current_user, "password", params["password"])
      true ->
        current_user  # No changes, preserve current state
    end

    {:noreply, assign(socket, user: user_params)}
  end

  defp authenticate_user(%{"email" => email, "password" => password}) do
    case Accounts.User.authenticate(email, password) do
      {:ok, user} -> {:ok, user}
      {:error, reason} -> {:error, reason}
    end
  end

  defp authenticate_user(_), do: {:error, "Invalid credentials"}
end
