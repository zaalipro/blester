defmodule BlesterWeb.ShopLive.Checkout do
  use BlesterWeb, :live_view
  import BlesterWeb.LiveValidations
  alias Blester.Shop

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]
    cart_count = if user_id, do: Shop.get_cart_count(user_id), else: 0
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
      user_id ->
        cart_items = Shop.get_user_cart(user_id)
        if length(cart_items) > 0 do
          {:ok, assign(socket, cart_items: cart_items, current_user_id: user_id, current_user: current_user, cart_count: cart_count)}
        else
          {:ok, push_navigate(socket, to: "/shop/cart")}
        end
    end
  end

  @impl true
  def handle_event("place_order", params, socket) do
    case Shop.create_order(socket.assigns.current_user_id, params) do
      {:ok, _order} ->
        cart_count = Shop.get_cart_count(socket.assigns.current_user_id)
        {:noreply, assign(socket, cart_count: cart_count) |> add_flash_timer(:info, "Order placed successfully!") |> push_navigate(to: "/shop")}
      {:error, _} ->
        {:noreply, add_flash_timer(socket, :error, "Failed to place order")}
    end
  end

  @impl true
  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end

  @impl true
  def render(_assigns) do
    # ... existing code ...
  end
end
