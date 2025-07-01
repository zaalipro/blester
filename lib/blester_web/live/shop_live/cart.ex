defmodule BlesterWeb.ShopLive.Cart do
  use BlesterWeb, :live_view
  alias Blester.Accounts
  alias BlesterWeb.LiveView.Authentication
  import BlesterWeb.LiveView.Authentication, only: [with_auth: 2]
  import BlesterWeb.LiveValidations, only: [add_flash_timer: 3]

  @impl true
  def mount(params, session, socket) do
    Authentication.mount_authenticated(params, session, socket, fn _params, socket ->
      case Accounts.get_cart_items(socket.assigns.current_user_id) do
        {:ok, cart_items} ->
          total = calculate_total(cart_items)
          {:ok, assign(socket, cart_items: cart_items, total: total)}
        {:error, _} ->
          {:ok, assign(socket, cart_items: [], total: Decimal.new(0))}
      end
    end)
  end

  @impl true
  def handle_event("update-quantity", %{"item-id" => item_id, "quantity" => quantity}, socket) do
    with_auth socket do
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
  end

  @impl true
  def handle_event("remove-item", %{"item-id" => item_id}, socket) do
    with_auth socket do
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
  end

  @impl true
  def handle_event("clear-cart", _params, socket) do
    with_auth socket do
      case Accounts.clear_cart(socket.assigns.current_user_id) do
        {:ok, _} ->
          {:noreply, assign(socket, cart_items: [], total: Decimal.new(0), cart_count: 0) |> add_flash_timer(:info, "Cart cleared")}
        {:error, _} ->
          {:noreply, add_flash_timer(socket, :error, "Failed to clear cart")}
      end
    end
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

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <div class="max-w-4xl mx-auto">
        <div class="mb-8">
          <a href="/shop" class="text-blue-600 hover:text-blue-800">
            ← Continue Shopping
          </a>
        </div>

        <div class="bg-white rounded-lg shadow-md">
          <div class="px-6 py-4 border-b border-gray-200">
            <h1 class="text-2xl font-bold text-gray-900">Shopping Cart</h1>
          </div>

          <%= if length(@cart_items) > 0 do %>
            <div class="divide-y divide-gray-200">
              <%= for item <- @cart_items do %>
                <div class="p-6 flex items-center space-x-4">
                  <div class="flex-shrink-0">
                    <img src={item.product.image_url} alt={item.product.name} class="w-16 h-16 object-cover rounded-md" />
                  </div>
                  <div class="flex-1 min-w-0">
                    <h3 class="text-lg font-medium text-gray-900">
                      <.link navigate={"/shop/#{item.product.id}"} class="hover:text-blue-600">
                        <%= item.product.name %>
                      </.link>
                    </h3>
                    <p class="text-sm text-gray-500"><%= item.product.description %></p>
                    <p class="text-lg font-semibold text-gray-900">$<%= format_price(item.product.price) %></p>
                  </div>
                  <div class="flex items-center space-x-2">
                    <label for={"quantity-#{item.id}"} class="text-sm font-medium text-gray-700">Qty:</label>
                    <select
                      id={"quantity-#{item.id}"}
                      phx-change="update-quantity"
                      phx-value-item-id={item.id}
                      class="border border-gray-300 rounded-md px-2 py-1 text-sm">
                      <%= for qty <- 1..10 do %>
                        <option value={qty} selected={qty == item.quantity}><%= qty %></option>
                      <% end %>
                    </select>
                  </div>
                  <div class="text-right">
                    <p class="text-lg font-semibold text-gray-900">$<%= format_price(Decimal.mult(item.product.price, item.quantity)) %></p>
                    <button
                      phx-click="remove-item"
                      phx-value-item-id={item.id}
                      class="text-red-600 hover:text-red-800 text-sm">
                      Remove
                    </button>
                  </div>
                </div>
              <% end %>
            </div>

            <div class="px-6 py-4 border-t border-gray-200">
              <div class="flex justify-between items-center">
                <div>
                  <button
                    phx-click="clear-cart"
                    onclick="return confirm('Are you sure you want to clear your cart?')"
                    class="text-red-600 hover:text-red-800 text-sm">
                    Clear Cart
                  </button>
                </div>
                <div class="text-right">
                  <p class="text-lg font-semibold text-gray-900">Total: $<%= format_price(@total) %></p>
                  <div class="mt-4 space-x-4">
                    <.link navigate="/shop" class="btn btn-secondary">Continue Shopping</.link>
                    <.link navigate="/checkout" class="btn btn-primary">Proceed to Checkout</.link>
                  </div>
                </div>
              </div>
            </div>
          <% else %>
            <div class="p-12 text-center">
              <div class="text-gray-400 mb-4">
                <svg class="mx-auto h-12 w-12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4m0 0L7 13m0 0l-2.5 5M7 13l2.5 5m6-5v6a2 2 0 01-2 2H9a2 2 0 01-2-2v-6m6 0V9a2 2 0 00-2-2H9a2 2 0 00-2 2v4.01" />
                </svg>
              </div>
              <h3 class="text-lg font-medium text-gray-900 mb-2">Your cart is empty</h3>
              <p class="text-gray-500 mb-6">Start shopping to add items to your cart.</p>
              <.link navigate="/shop" class="btn btn-primary">Start Shopping</.link>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
