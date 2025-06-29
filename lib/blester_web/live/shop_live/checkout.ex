defmodule BlesterWeb.ShopLive.Checkout do
  use BlesterWeb, :live_view
  alias Blester.Accounts

  @impl true
  def mount(_params, _session, socket) do
    case socket.assigns[:current_user_id] do
      nil ->
        {:ok, push_navigate(socket, to: "/login")}
      user_id ->
        cart_items = Accounts.get_user_cart(user_id)
        total = calculate_total(cart_items)
        {:ok, assign(socket, cart_items: cart_items, total: total, step: :form, order: nil, error: nil)}
    end
  end

  @impl true
  def handle_event("place-order", params, socket) do
    user_id = socket.assigns.current_user_id
    cart_items = socket.assigns.cart_items
    total = socket.assigns.total
    order_params = %{
      user_id: user_id,
      order_number: Accounts.generate_order_number(),
      status: "pending",
      total_amount: total,
      shipping_address: params["shipping_address"],
      billing_address: params["billing_address"],
      payment_method: params["payment_method"]
    }
    case Accounts.place_order(order_params, cart_items) do
      {:ok, order} ->
        {:noreply, assign(socket, step: :success, order: order)}
      {:error, changeset} ->
        {:noreply, assign(socket, error: "Failed to place order: #{inspect(changeset.errors)}")}
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
