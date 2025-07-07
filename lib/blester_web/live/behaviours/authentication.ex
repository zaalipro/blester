defmodule BlesterWeb.LiveView.Authentication do
  @moduledoc """
  Behaviour for handling authentication in LiveViews.
  """

  import Phoenix.LiveView, only: [push_navigate: 2]

  @callback require_authentication(socket :: Phoenix.LiveView.Socket.t()) ::
              {:ok, Phoenix.LiveView.Socket.t()} | {:error, :redirect}

  @callback require_admin(socket :: Phoenix.LiveView.Socket.t()) ::
              {:ok, Phoenix.LiveView.Socket.t()} | {:error, :redirect}

  @doc """
  Standard authentication check for LiveViews.
  Returns {:ok, socket} if authenticated, {:error, :redirect} if not.
  """
  def require_authentication(socket) do
    case socket.assigns[:current_user_id] do
      nil ->
        {:error, :redirect}
      _user_id ->
        case socket.assigns[:current_user] do
          nil ->
            {:error, :redirect}
          user when not is_nil(user) ->
            {:ok, socket}
        end
    end
  end

  @doc """
  Standard admin authorization check for LiveViews.
  Returns {:ok, socket} if admin, {:error, :redirect} if not.
  """
  def require_admin(socket) do
    case require_authentication(socket) do
      {:ok, socket} ->
        user = socket.assigns[:current_user]
        if user.role == "admin" do
          {:ok, socket}
        else
          {:error, :redirect}
        end
      {:error, :redirect} ->
        {:error, :redirect}
    end
  end

  @doc """
  Standard mount function for authenticated LiveViews.
  """
  def mount_authenticated(params, session, socket, callback) do
    user_id = session["user_id"]

    cart_count = if user_id, do: Blester.Shop.get_cart_count(user_id), else: 0
    current_user = case user_id do
      nil -> nil
      id -> case Blester.Accounts.get_user(id) do
        {:ok, user} -> user
        _ -> nil
      end
    end

    case user_id do
      nil ->
        {:ok, push_navigate(socket, to: "/login")}
      _user_id ->
        if current_user do
          socket = %{socket | assigns: Map.merge(socket.assigns, %{
            current_user_id: user_id,
            current_user: current_user,
            cart_count: cart_count
          })}
          callback.(params, socket)
        else
          {:ok, push_navigate(socket, to: "/login")}
        end
    end
  end

  @doc """
  Standard mount function for admin LiveViews.
  """
  def mount_admin(params, session, socket, callback) do
    mount_authenticated(params, session, socket, fn params, socket ->
      user = socket.assigns[:current_user]
      if user.role == "admin" do
        callback.(params, socket)
      else
        {:ok, push_navigate(socket, to: "/")}
      end
    end)
  end

  @doc """
  Macro to wrap event handlers that require authentication in LiveViews.
  Usage:
    with_auth socket do
      # your logic
    end
  """
  defmacro with_auth(socket, do: block) do
    quote do
      case BlesterWeb.LiveView.Authentication.require_authentication(unquote(socket)) do
        {:ok, socket} -> unquote(block)
        {:error, :redirect} -> {:noreply, Phoenix.LiveView.push_navigate(unquote(socket), to: "/login")}
      end
    end
  end
end
