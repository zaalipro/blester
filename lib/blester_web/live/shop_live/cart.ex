defmodule BlesterWeb.ShopLive.Cart do
  use BlesterWeb, :live_view
  alias Blester.Accounts

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]
    case user_id do
      nil ->
        {:ok, push_navigate(socket, to: "/login")}
      user_id ->
        cart_items = Accounts.get_user_cart(user_id)
        total = calculate_total(cart_items)
        {:ok, assign(socket, cart_items: cart_items, total: total, current_user_id: user_id)}
    end
  end

  @impl true
  def handle_event("update-quantity", %{"item-id" => item_id, "quantity" => quantity}, socket) do
    quantity = String.to_integer(quantity)
    case Accounts.update_cart_item_quantity(item_id, quantity) do
      {:ok, _cart_item} ->
        cart_items = Accounts.get_user_cart(socket.assigns.current_user_id)
        total = calculate_total(cart_items)
        {:noreply, assign(socket, cart_items: cart_items, total: total)}
      {:error, _changeset} ->
        {:noreply, socket |> put_flash(:error, "Failed to update quantity")}
    end
  end

  @impl true
  def handle_event("remove-item", %{"item-id" => item_id}, socket) do
    case Accounts.remove_from_cart(item_id) do
      {:ok, _} ->
        cart_items = Accounts.get_user_cart(socket.assigns.current_user_id)
        total = calculate_total(cart_items)
        {:noreply, assign(socket, cart_items: cart_items, total: total) |> put_flash(:info, "Item removed from cart")}
      {:error, _} ->
        {:noreply, socket |> put_flash(:error, "Failed to remove item")}
    end
  end

  @impl true
  def handle_event("proceed-to-checkout", _params, socket) do
    if length(socket.assigns.cart_items) > 0 do
      {:noreply, push_navigate(socket, to: "/checkout")}
    else
      {:noreply, socket |> put_flash(:error, "Your cart is empty")}
    end
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
