defmodule BlesterWeb.AdminLive.Orders do
  use BlesterWeb, :live_view
  import BlesterWeb.LiveValidations
  alias Blester.Shop

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]
    cart_count = if user_id, do: Blester.Shop.get_cart_count(user_id), else: 0

    case user_id do
      nil ->
        {:ok, push_navigate(socket, to: "/login")}
      user_id ->
        case Shop.get_user(user_id) do
          {:ok, user} when not is_nil(user) ->
            if user.role == "admin" do
              {:ok, assign(socket,
                current_user: user,
                current_user_id: user_id,
                cart_count: cart_count,
                orders: [],
                search: "",
                status: "all",
                page: 1,
                per_page: 10,
                total_count: 0,
                total_pages: 0
              ) |> load_orders()}
            else
              {:ok, push_navigate(socket, to: "/")}
            end
          _ ->
            {:ok, push_navigate(socket, to: "/login")}
        end
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    search = Map.get(params, "search", "")
    status = Map.get(params, "status", "all")

    {:noreply, assign(socket, page: page, search: search, status: status) |> load_orders()}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    {:noreply, push_patch(socket, to: "/admin/orders?search=#{search}&status=#{socket.assigns.status}")}
  end

  @impl true
  def handle_event("filter-status", %{"status" => status}, socket) do
    {:noreply, push_patch(socket, to: "/admin/orders?search=#{socket.assigns.search}&status=#{status}")}
  end

  @impl true
  def handle_event("update-status", %{"id" => id, "status" => status}, socket) do
    case Blester.Shop.update_order_status(id, status) do
      {:ok, _order} ->
        {:noreply, load_orders(socket) |> add_flash_timer(:info, "Order status updated successfully")}
      {:error, _} ->
        {:noreply, add_flash_timer(socket, :error, "Failed to update order status")}
    end
  end

  @impl true
  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end

  defp load_orders(socket) do
    offset = (socket.assigns.page - 1) * socket.assigns.per_page

    case Shop.list_orders_paginated(
      socket.assigns.per_page,
      offset,
      socket.assigns.search,
      socket.assigns.status
    ) do
      {:ok, {orders, total_count}} ->
        total_pages = ceil(total_count / socket.assigns.per_page)
        assign(socket, orders: orders, total_count: total_count, total_pages: total_pages)
      {:error, _} ->
        assign(socket, orders: [], total_count: 0, total_pages: 0)
    end
  end

  defp get_status_color(status) do
    case status do
      "pending" -> "bg-yellow-100 text-yellow-800"
      "processing" -> "bg-blue-100 text-blue-800"
      "shipped" -> "bg-purple-100 text-purple-800"
      "delivered" -> "bg-green-100 text-green-800"
      "cancelled" -> "bg-red-100 text-red-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  defp format_price(price) do
    Decimal.to_string(price, :normal)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <!-- Admin Header -->
      <div class="bg-white shadow-sm border-b border-gray-200">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex justify-between items-center py-6">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <h1 class="text-2xl font-bold text-gray-900">Order Management</h1>
              </div>
            </div>
            <div class="flex items-center space-x-4">
              <a href="/admin/dashboard" class="text-gray-500 hover:text-gray-700 text-sm font-medium">Dashboard</a>
            </div>
          </div>
        </div>
      </div>

      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <!-- Filters -->
        <div class="bg-white shadow rounded-lg mb-6">
          <div class="p-6">
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <!-- Search -->
              <div>
                <label for="search" class="block text-sm font-medium text-gray-700 mb-2">Search Orders</label>
                <form phx-change="search" class="relative">
                  <input
                    type="text"
                    name="search"
                    id="search"
                    value={@search}
                    placeholder="Search by order ID, customer name..."
                    class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                  <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <svg class="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
                    </svg>
                  </div>
                </form>
              </div>

              <!-- Status Filter -->
              <div>
                <label for="status" class="block text-sm font-medium text-gray-700 mb-2">Status</label>
                <form phx-change="filter-status">
                  <select
                    name="status"
                    id="status"
                    value={@status}
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  >
                    <option value="all">All Statuses</option>
                    <option value="pending">Pending</option>
                    <option value="processing">Processing</option>
                    <option value="shipped">Shipped</option>
                    <option value="delivered">Delivered</option>
                    <option value="cancelled">Cancelled</option>
                  </select>
                </form>
              </div>

              <!-- Results Count -->
              <div class="flex items-end">
                <p class="text-sm text-gray-500">
                  <%= @total_count %> orders found
                </p>
              </div>
            </div>
          </div>
        </div>

        <!-- Orders Table -->
        <div class="bg-white shadow rounded-lg overflow-hidden">
          <%= if Enum.empty?(@orders) do %>
            <div class="text-center py-12">
              <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path>
              </svg>
              <h3 class="mt-2 text-sm font-medium text-gray-900">No orders found</h3>
              <p class="mt-1 text-sm text-gray-500">Orders will appear here when customers make purchases.</p>
            </div>
          <% else %>
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Order ID</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Customer</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Items</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Total</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <%= for order <- @orders do %>
                    <tr class="hover:bg-gray-50">
                      <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                        #<%= String.slice(order.id, 0, 8) %>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="text-sm text-gray-900">
                          <%= order.user.first_name %> <%= order.user.last_name %>
                        </div>
                        <div class="text-sm text-gray-500">
                          <%= order.user.email %>
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        <%= length(order.order_items) %> items
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        $<%= format_price(order.total_amount) %>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <span class={"inline-flex px-2 py-1 text-xs font-semibold rounded-full #{get_status_color(order.status)}"}>
                          <%= String.capitalize(order.status) %>
                        </span>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        <%= Calendar.strftime(order.inserted_at, "%b %d, %Y") %>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                        <div class="flex items-center space-x-2">
                          <a href={"/admin/orders/#{order.id}"} class="text-blue-600 hover:text-blue-900">View</a>
                          <select
                            phx-change="update-status"
                            phx-value-id={order.id}
                            class="text-xs border border-gray-300 rounded px-2 py-1"
                          >
                            <option value="">Change Status</option>
                            <option value="pending">Pending</option>
                            <option value="processing">Processing</option>
                            <option value="shipped">Shipped</option>
                            <option value="delivered">Delivered</option>
                            <option value="cancelled">Cancelled</option>
                          </select>
                        </div>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>

            <!-- Pagination -->
            <%= if @total_pages > 1 do %>
              <div class="bg-white px-4 py-3 flex items-center justify-between border-t border-gray-200 sm:px-6">
                <div class="flex-1 flex justify-between sm:hidden">
                  <%= if @page > 1 do %>
                    <a href={"/admin/orders?page=#{@page - 1}&search=#{@search}&status=#{@status}"} class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
                      Previous
                    </a>
                  <% end %>
                  <%= if @page < @total_pages do %>
                    <a href={"/admin/orders?page=#{@page + 1}&search=#{@search}&status=#{@status}"} class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
                      Next
                    </a>
                  <% end %>
                </div>
                <div class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
                  <div>
                    <p class="text-sm text-gray-700">
                      Showing <span class="font-medium"><%= (@page - 1) * @per_page + 1 %></span> to <span class="font-medium"><%= min(@page * @per_page, @total_count) %></span> of <span class="font-medium"><%= @total_count %></span> results
                    </p>
                  </div>
                  <div>
                    <nav class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px">
                      <%= if @page > 1 do %>
                        <a href={"/admin/orders?page=#{@page - 1}&search=#{@search}&status=#{@status}"} class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50">
                          <span class="sr-only">Previous</span>
                          <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
                          </svg>
                        </a>
                      <% end %>

                      <%= for page_num <- max(1, @page - 2)..min(@total_pages, @page + 2) do %>
                        <a
                          href={"/admin/orders?page=#{page_num}&search=#{@search}&status=#{@status}"}
                          class={"relative inline-flex items-center px-4 py-2 border text-sm font-medium #{if page_num == @page, do: "z-10 bg-blue-50 border-blue-500 text-blue-600", else: "bg-white border-gray-300 text-gray-500 hover:bg-gray-50"}"}
                        >
                          <%= page_num %>
                        </a>
                      <% end %>

                      <%= if @page < @total_pages do %>
                        <a href={"/admin/orders?page=#{@page + 1}&search=#{@search}&status=#{@status}"} class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50">
                          <span class="sr-only">Next</span>
                          <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
                          </svg>
                        </a>
                      <% end %>
                    </nav>
                  </div>
                </div>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
