defmodule BlesterWeb.AuthLive.Register do
  use BlesterWeb, :live_view

  alias Blester.Accounts

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"] || session[:user_id]
    {:ok,
     socket
     |> assign(current_user_id: user_id)
     |> assign(:page_title, "Register")
     |> assign(:user, %{email: "", password: "", password_confirmation: "", first_name: "", last_name: "", country: ""})
     |> assign(:errors, [])}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    # Hash the password and prepare user params for Ash
    hashed_password = Blester.Accounts.User.hash_password(user_params["password"])

    # Convert to atom keys and use hashed_password instead of password
    ash_params = %{
      email: user_params["email"],
      hashed_password: hashed_password,
      first_name: user_params["first_name"],
      last_name: user_params["last_name"],
      country: user_params["country"]
    }

    case Blester.Accounts.create_user(ash_params) do
      {:ok, user} ->
        # Redirect to controller action to set session
        {:noreply,
         socket
         |> put_flash(:info, "Account created successfully!")
         |> push_navigate(to: "/auth/set_session?user_id=#{user.id}")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to create account")
         |> assign(user: user_params)
         |> assign(errors: format_errors(changeset))}
    end
  end

  @impl true
  def handle_event("save", params, socket) do
    # Handle the case where params come directly without the "user" wrapper
    user_params = %{
      "first_name" => params["first_name"] || "",
      "last_name" => params["last_name"] || "",
      "email" => params["email"] || "",
      "country" => params["country"] || "",
      "password" => params["password"] || "",
      "password_confirmation" => params["password_confirmation"] || ""
    }

    case create_user(user_params) do
      {:ok, user} ->
        # Redirect to controller action to set session
        {:noreply,
         socket
         |> put_flash(:info, "Account created successfully!")
         |> push_navigate(to: "/auth/set_session?user_id=#{user.id}")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to create account")
         |> assign(user: user_params)
         |> assign(errors: format_errors(changeset))}
    end
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    {:noreply, assign(socket, user: user_params)}
  end

  @impl true
  def handle_event("validate", params, socket) do
    # Handle individual field validation with explicit state preservation
    current_user = socket.assigns.user

    # Get the target field from the _target parameter
    target_field = case params["_target"] do
      [field] -> field
      _ -> nil
    end

    # Create a new user map with all current values
    user_params = %{
      "first_name" => current_user["first_name"] || "",
      "last_name" => current_user["last_name"] || "",
      "email" => current_user["email"] || "",
      "country" => current_user["country"] || "",
      "password" => current_user["password"] || "",
      "password_confirmation" => current_user["password_confirmation"] || ""
    }

    # Update only the specific field that changed
    user_params = case target_field do
      "first_name" ->
        Map.put(user_params, "first_name", params["first_name"] || "")
      "last_name" ->
        Map.put(user_params, "last_name", params["last_name"] || "")
      "email" ->
        Map.put(user_params, "email", params["email"] || "")
      "country" ->
        Map.put(user_params, "country", params["country"] || "")
      "password" ->
        Map.put(user_params, "password", params["password"] || "")
      "password_confirmation" ->
        Map.put(user_params, "password_confirmation", params["password_confirmation"] || "")
      _ ->
        user_params
    end

    {:noreply, assign(socket, user: user_params)}
  end

  defp create_user(user_params) do
    # Hash the password before creating the user
    user_params = Map.put(user_params, "hashed_password", Blester.Accounts.User.hash_password(user_params["password"]))
    user_params = Map.drop(user_params, ["password", "password_confirmation"])
    # Convert string keys to atoms for Ash
    user_params = for {k, v} <- user_params, into: %{}, do: {String.to_atom(k), v}

    Accounts.create_user(user_params)
  end

  defp format_errors(changeset) do
    # Handle Ash errors
    case changeset do
      %Ash.Error.Invalid{} = error ->
        # Extract error messages from Ash errors
        [{"error", Ash.Error.message(error)}]
      _ ->
        # Fallback for other error types
        [{"error", "An error occurred"}]
    end
  end
end
