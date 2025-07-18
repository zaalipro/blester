defmodule BlesterWeb.ShopLive.Show do
  use BlesterWeb, :live_view
  import BlesterWeb.LiveValidations
  alias Blester.Shop

  @impl true
  def mount(%{"id" => id}, session, socket) do
    user_id = session["user_id"]
    cart_count = if user_id, do: Shop.get_cart_count(user_id), else: 0
    current_user = case user_id do
      nil -> nil
      id -> case Blester.Accounts.get_user(id) do
        {:ok, user} -> user
        _ -> nil
      end
    end

    case Shop.get_product(id) do
      {:ok, product} ->
        {:ok, assign(socket, product: product, quantity: 1, current_user_id: user_id, current_user: current_user, cart_count: cart_count)}
      {:error, _} ->
        {:ok, push_navigate(socket, to: "/shop")}
    end
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    case Shop.get_product(id) do
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
        case Shop.add_to_cart(user_id, socket.assigns.product.id, String.to_integer(quantity)) do
          {:ok, _cart_item} ->
            cart_count = Shop.get_cart_count(user_id)
            {:noreply, assign(socket, cart_count: cart_count) |> add_flash_timer(:info, "Product added to cart!")}
          {:error, _} ->
            {:noreply, add_flash_timer(socket, :error, "Failed to add product to cart")}
        end
    end
  end

  @impl true
  def handle_event("update-quantity", %{"quantity" => quantity}, socket) do
    {:noreply, assign(socket, quantity: String.to_integer(quantity))}
  end

  @impl true
  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end

  defp format_price(price) do
    Decimal.to_string(price, :normal)
  end
end
