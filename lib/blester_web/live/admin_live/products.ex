defmodule BlesterWeb.AdminLive.Products do
  use BlesterWeb, :live_view
  alias Blester.Shop
  import BlesterWeb.LiveValidations, only: [add_flash_timer: 3]

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]
    cart_count = if user_id, do: Blester.Shop.get_cart_count(user_id), else: 0

    case user_id do
      nil ->
        {:ok, push_navigate(socket, to: "/login")}
      user_id ->
        case Blester.Accounts.get_user(user_id) do
          {:ok, user} when not is_nil(user) ->
            if user.role == "admin" do
              {:ok, assign(socket,
                current_user: user,
                current_user_id: user_id,
                cart_count: cart_count,
                products: [],
                search: "",
                category: "all",
                page: 1,
                per_page: 10,
                total_count: 0,
                total_pages: 0
              ) |> load_products()}
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
    category = Map.get(params, "category", "all")

    {:noreply, assign(socket, page: page, search: search, category: category) |> load_products()}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    {:noreply, push_patch(socket, to: "/admin/products?search=#{search}&category=#{socket.assigns.category}")}
  end

  @impl true
  def handle_event("filter-category", %{"category" => category}, socket) do
    {:noreply, push_patch(socket, to: "/admin/products?search=#{socket.assigns.search}&category=#{category}")}
  end

  @impl true
  def handle_event("delete-product", %{"id" => id}, socket) do
    case Shop.delete_product(id) do
      {:ok, _} ->
        {:noreply, load_products(socket) |> add_flash_timer(:info, "Product deleted successfully")}
      {:error, _} ->
        {:noreply, add_flash_timer(socket, :error, "Failed to delete product")}
    end
  end

  @impl true
  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end

  defp load_products(socket) do
    offset = (socket.assigns.page - 1) * socket.assigns.per_page

    case Blester.Shop.list_products_paginated_admin(
      socket.assigns.per_page,
      offset,
      socket.assigns.search,
      socket.assigns.category
    ) do
      {:ok, {products, total_count}} ->
        total_pages = ceil(total_count / socket.assigns.per_page)
        assign(socket, products: products, total_count: total_count, total_pages: total_pages)
      {:error, _} ->
        assign(socket, products: [], total_count: 0, total_pages: 0)
    end
  end

  defp get_status_color(status) do
    case status do
      "active" -> "bg-green-100 text-green-800"
      "inactive" -> "bg-red-100 text-red-800"
      "draft" -> "bg-yellow-100 text-yellow-800"
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
                <h1 class="text-2xl font-bold text-gray-900">Product Management</h1>
              </div>
            </div>
            <div class="flex items-center space-x-4">
              <a href="/admin/dashboard" class="text-gray-500 hover:text-gray-700 text-sm font-medium">Dashboard</a>
              <a href="/admin/products/new" class="bg-blue-600 text-white px-4 py-2 rounded-md text-sm font-medium hover:bg-blue-700">
                Add Product
              </a>
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
                <label for="search" class="block text-sm font-medium text-gray-700 mb-2">Search Products</label>
                <form phx-change="search" class="relative">
                  <input
                    type="text"
                    name="search"
                    id="search"
                    value={@search}
                    placeholder="Search by name, description..."
                    class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                  <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <svg class="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
                    </svg>
                  </div>
                </form>
              </div>

              <!-- Category Filter -->
              <div>
                <label for="category" class="block text-sm font-medium text-gray-700 mb-2">Category</label>
                <form phx-change="filter-category">
                  <select
                    name="category"
                    id="category"
                    value={@category}
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  >
                    <option value="all">All Categories</option>
                    <option value="electronics">Electronics</option>
                    <option value="clothing">Clothing</option>
                    <option value="books">Books</option>
                    <option value="home">Home & Garden</option>
                    <option value="sports">Sports</option>
                  </select>
                </form>
              </div>

              <!-- Results Count -->
              <div class="flex items-end">
                <p class="text-sm text-gray-500">
                  <%= @total_count %> products found
                </p>
              </div>
            </div>
          </div>
        </div>

        <!-- Products Table -->
        <div class="bg-white shadow rounded-lg overflow-hidden">
          <%= if Enum.empty?(@products) do %>
            <div class="text-center py-12">
              <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"></path>
              </svg>
              <h3 class="mt-2 text-sm font-medium text-gray-900">No products found</h3>
              <p class="mt-1 text-sm text-gray-500">Get started by creating a new product.</p>
              <div class="mt-6">
                <a href="/admin/products/new" class="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700">
                  <svg class="-ml-1 mr-2 h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
                  </svg>
                  Add Product
                </a>
              </div>
            </div>
          <% else %>
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Product</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Category</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Price</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Stock</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <%= for product <- @products do %>
                    <tr class="hover:bg-gray-50">
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="flex items-center">
                          <div class="flex-shrink-0 h-10 w-10">
                            <img class="h-10 w-10 rounded-lg object-cover" src={product.image_url} alt={product.name} />
                          </div>
                          <div class="ml-4">
                            <div class="text-sm font-medium text-gray-900"><%= product.name %></div>
                            <div class="text-sm text-gray-500"><%= String.slice(product.description, 0, 50) %><%= if String.length(product.description) > 50, do: "...", else: "" %></div>
                          </div>
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        <%= String.capitalize(product.category) %>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        $<%= format_price(product.price) %>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        <%= product.stock_quantity %>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <span class={"inline-flex px-2 py-1 text-xs font-semibold rounded-full #{get_status_color(product.status)}"}>
                          <%= String.capitalize(product.status) %>
                        </span>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                        <div class="flex items-center space-x-2">
                          <a href={"/admin/products/#{product.id}/edit"} class="text-blue-600 hover:text-blue-900">Edit</a>
                          <button
                            phx-click="delete-product"
                            phx-value-id={product.id}
                            data-confirm="Are you sure you want to delete this product?"
                            class="text-red-600 hover:text-red-900"
                          >
                            Delete
                          </button>
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
                    <a href={"/admin/products?page=#{@page - 1}&search=#{@search}&category=#{@category}"} class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
                      Previous
                    </a>
                  <% end %>
                  <%= if @page < @total_pages do %>
                    <a href={"/admin/products?page=#{@page + 1}&search=#{@search}&category=#{@category}"} class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
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
                        <a href={"/admin/products?page=#{@page - 1}&search=#{@search}&category=#{@category}"} class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50">
                          <span class="sr-only">Previous</span>
                          <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
                          </svg>
                        </a>
                      <% end %>

                      <%= for page_num <- max(1, @page - 2)..min(@total_pages, @page + 2) do %>
                        <a
                          href={"/admin/products?page=#{page_num}&search=#{@search}&category=#{@category}"}
                          class={"relative inline-flex items-center px-4 py-2 border text-sm font-medium #{if page_num == @page, do: "z-10 bg-blue-50 border-blue-500 text-blue-600", else: "bg-white border-gray-300 text-gray-500 hover:bg-gray-50"}"}
                        >
                          <%= page_num %>
                        </a>
                      <% end %>

                      <%= if @page < @total_pages do %>
                        <a href={"/admin/products?page=#{@page + 1}&search=#{@search}&category=#{@category}"} class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50">
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
