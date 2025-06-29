defmodule BlesterWeb.ShopLive.Cart do
  use BlesterWeb, :live_view
  import BlesterWeb.LiveValidations
  alias Blester.Accounts

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]
    cart_count = if user_id, do: Accounts.get_cart_count(user_id), else: 0
    case user_id do
      nil ->
        {:ok, push_navigate(socket, to: "/login")}
      user_id ->
        case Accounts.get_cart_items(user_id) do
          {:ok, cart_items} ->
            total = calculate_total(cart_items)
            {:ok, assign(socket, cart_items: cart_items, total: total, current_user_id: user_id, cart_count: cart_count)}
          {:error, _} ->
            {:ok, assign(socket, cart_items: [], total: Decimal.new(0), current_user_id: user_id, cart_count: cart_count)}
        end
    end
  end

  @impl true
  def handle_event("update-quantity", %{"item-id" => item_id, "quantity" => quantity}, socket) do
    case Accounts.update_cart_item_quantity(item_id, String.to_integer(quantity)) do
      {:ok, _} ->
        case Accounts.get_cart_items(socket.assigns.current_user_id) do
          {:ok, cart_items} ->
            cart_count = Accounts.get_cart_count(socket.assigns.current_user_id)
            total = calculate_total(cart_items)
            {:noreply, assign(socket, cart_items: cart_items, total: total, cart_count: cart_count) |> add_flash_timer(:info, "Cart updated")}
          {:error, _} ->
            {:noreply, add_flash_timer(socket, :error, "Failed to update cart")}
        end
      {:error, _} ->
        {:noreply, add_flash_timer(socket, :error, "Failed to update quantity")}
    end
  end

  @impl true
  def handle_event("remove-item", %{"item-id" => item_id}, socket) do
    case Accounts.remove_from_cart(item_id) do
      {:ok, _} ->
        case Accounts.get_cart_items(socket.assigns.current_user_id) do
          {:ok, cart_items} ->
            cart_count = Accounts.get_cart_count(socket.assigns.current_user_id)
            total = calculate_total(cart_items)
            {:noreply, assign(socket, cart_items: cart_items, total: total, cart_count: cart_count) |> add_flash_timer(:info, "Item removed from cart")}
          {:error, _} ->
            {:noreply, add_flash_timer(socket, :error, "Failed to update cart")}
        end
      {:error, _} ->
        {:noreply, add_flash_timer(socket, :error, "Failed to remove item")}
    end
  end

  @impl true
  def handle_event("proceed-to-checkout", _params, socket) do
    {:noreply, push_navigate(socket, to: "/shop/checkout")}
  end

  @impl true
  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end

  defp calculate_total(cart_items) do
    cart_items
    |> Enum.reduce(Decimal.new(0), fn item, acc ->
      item_total = Decimal.mult(item.product.price, item.quantity)
      Decimal.add(acc, item_total)
    end)
  end

  defp format_price(price) do
    Decimal.to_string(price, :normal)
  end
end
