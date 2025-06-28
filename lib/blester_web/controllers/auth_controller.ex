defmodule BlesterWeb.AuthController do
  use Phoenix.Controller, layouts: [html: {BlesterWeb.Layouts, :app}]
  import Plug.Conn
  import BlesterWeb.Gettext

  # Plug to redirect authenticated users away from auth pages
  plug :redirect_if_authenticated when action in [:login, :register, :create_user, :authenticate_user]

  def login(conn, _params) do
    render(conn, :login)
  end

  def register(conn, _params) do
    render(conn, :register)
  end

  def create_user(conn, %{"user" => user_params}) do
    IO.inspect("Creating user with params: #{inspect(user_params)}")
    # Hash the password before creating the user
    user_params = Map.put(user_params, "hashed_password", Blester.Accounts.User.hash_password(user_params["password"]))
    user_params = Map.drop(user_params, ["password", "password_confirmation"])
    # Convert string keys to atoms for Ash
    user_params = for {k, v} <- user_params, into: %{}, do: {String.to_atom(k), v}

    case Blester.Accounts.create_user(user_params) do
      {:ok, user} ->
        IO.inspect("User created successfully: #{user.email}")
        conn
        |> put_flash(:info, "Account created successfully!")
        |> redirect(to: "/")

      {:error, changeset} ->
        IO.inspect("User creation failed: #{inspect(changeset)}")
        conn
        |> put_flash(:error, "Failed to create account")
        |> render(:register, changeset: changeset)
    end
  end

  def authenticate_user(conn, %{"user" => %{"email" => email, "password" => password}}) do
    IO.inspect("Attempting to authenticate user: #{email}")
    case Blester.Accounts.User.authenticate(email, password) do
      {:ok, user} ->
        IO.inspect("Authentication successful for user: #{user.email}")
        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: "/")

      {:error, reason} ->
        IO.inspect("Authentication failed: #{inspect(reason)}")
        conn
        |> put_flash(:error, "Invalid email or password")
        |> render(:login)
    end
  end

  def logout(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "You have been logged out.")
    |> redirect(to: "/")
  end

  # Private function to redirect authenticated users
  defp redirect_if_authenticated(conn, _opts) do
    if conn.assigns[:current_user_id] do
      conn
      |> put_flash(:info, "You are already logged in.")
      |> redirect(to: "/")
      |> halt()
    else
      conn
    end
  end
end
