defmodule BlesterWeb.ShopLive.Show do
  use BlesterWeb, :live_view
  alias Blester.Accounts

  @impl true
  def mount(%{"id" => id}, session, socket) do
    user_id = session["user_id"]
    cart_count = if user_id, do: Accounts.get_cart_count(user_id), else: 0

    case Accounts.get_product(id) do
      {:ok, product} ->
        {:ok, assign(socket, product: product, current_user_id: user_id, cart_count: cart_count)}
      {:error, _} ->
        {:ok, push_navigate(socket, to: "/shop")}
    end
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    case Accounts.get_product(id) do
      {:ok, product} ->
        {:noreply, assign(socket, product: product)}
      {:error, _} ->
        {:noreply, push_navigate(socket, to: "/shop")}
    end
  end

  @impl true
  def handle_event("add-to-cart", %{"quantity" => quantity}, socket) do
    case socket.assigns.current_user_id do
      nil ->
        {:noreply, push_navigate(socket, to: "/login")}
      user_id ->
        quantity = String.to_integer(quantity)
        case Accounts.add_to_cart(user_id, socket.assigns.product.id, quantity) do
          {:ok, _cart_item} ->
            cart_count = Accounts.get_cart_count(user_id)
            {:noreply, socket
              |> assign(cart_count: cart_count)
              |> put_flash(:info, "Product added to cart!")}
          {:error, _changeset} ->
            {:noreply, socket |> put_flash(:error, "Failed to add product to cart")}
        end
    end
  end

  @impl true
  def handle_event("update-quantity", %{"quantity" => quantity}, socket) do
    quantity = String.to_integer(quantity)
    {:noreply, assign(socket, quantity: max(1, quantity))}
  end

  defp format_price(price) do
    Decimal.to_string(price, :normal)
  end
end
