defmodule BlesterWeb.AdminLive.Products.Edit do
  use BlesterWeb, :live_view
  import BlesterWeb.LiveValidations
  alias Blester.Accounts

  @impl true
  def mount(%{"id" => id}, session, socket) do
    user_id = session["user_id"]
    cart_count = if user_id, do: Accounts.get_cart_count(user_id), else: 0

    case user_id do
      nil ->
        {:ok, push_navigate(socket, to: "/login")}
      user_id ->
        case Accounts.get_user(user_id) do
          {:ok, user} when not is_nil(user) ->
            if user.role == "admin" do
              case Accounts.get_product(id) do
                {:ok, product} ->
                  {:ok, assign(socket,
                    current_user: user,
                    current_user_id: user_id,
                    cart_count: cart_count,
                    product: %{
                      "name" => product.name,
                      "description" => product.description,
                      "price" => Decimal.to_string(product.price, :normal),
                      "stock_quantity" => to_string(product.stock_quantity),
                      "category" => product.category,
                      "image_url" => product.image_url,
                      "status" => product.status
                    },
                    errors: %{}
                  )}
                {:error, _} ->
                  {:ok, push_navigate(socket, to: "/admin/products") |> add_flash_timer(:error, "Product not found")}
              end
            else
              {:ok, push_navigate(socket, to: "/")}
            end
          _ ->
            {:ok, push_navigate(socket, to: "/login")}
        end
    end
  end

  @impl true
  def handle_event("save", %{"product" => product_params}, socket) do
    case validate_product(product_params) do
      {:ok, validated_params} ->
        case Accounts.update_product(socket.assigns.product_id, validated_params) do
          {:ok, _product} ->
            {:noreply, push_navigate(socket, to: "/admin/products") |> add_flash_timer(:info, "Product updated successfully")}
          {:error, changeset} ->
            {:noreply, assign(socket, errors: format_changeset_errors(changeset))}
        end
      {:error, errors} ->
        {:noreply, assign(socket, errors: errors)}
    end
  end

  @impl true
  def handle_event("validate", %{"product" => product_params}, socket) do
    merged_params = Map.merge(socket.assigns.product, product_params)
    case validate_product(merged_params) do
      {:ok, _} ->
        {:noreply, assign(socket, product: merged_params, errors: %{})}
      {:error, errors} ->
        {:noreply, assign(socket, product: merged_params, errors: errors)}
    end
  end

  @impl true
  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end

  defp validate_product(params) do
    errors = %{}

    errors = if params["name"] == "" or params["name"] == nil, do: Map.put(errors, "name", ["Name is required"]), else: errors
    errors = if params["description"] == "" or params["description"] == nil, do: Map.put(errors, "description", ["Description is required"]), else: errors
    errors = if params["price"] == "" or params["price"] == nil, do: Map.put(errors, "price", ["Price is required"]), else: errors
    errors = if params["stock_quantity"] == "" or params["stock_quantity"] == nil, do: Map.put(errors, "stock_quantity", ["Stock quantity is required"]), else: errors
    errors = if params["category"] == "" or params["category"] == nil, do: Map.put(errors, "category", ["Category is required"]), else: errors

    # Validate price format
    errors = if params["price"] != "" and params["price"] != nil do
      case Decimal.parse(params["price"]) do
        {decimal, ""} when is_struct(decimal, Decimal) -> errors
        _ -> Map.put(errors, "price", ["Price must be a valid number"])
      end
    else
      errors
    end

    # Validate stock quantity
    errors = if params["stock_quantity"] != "" and params["stock_quantity"] != nil do
      case Integer.parse(params["stock_quantity"]) do
        {quantity, _} when quantity >= 0 -> errors
        _ -> Map.put(errors, "stock_quantity", ["Stock quantity must be a positive integer"])
      end
    else
      errors
    end

    if map_size(errors) > 0 do
      {:error, errors}
    else
      {:ok, params}
    end
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <!-- Admin Header -->
      <div class="bg-white shadow-sm border-b border-gray-200">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex justify-between items-center py-6">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <h1 class="text-2xl font-bold text-gray-900">Edit Product</h1>
              </div>
            </div>
            <div class="flex items-center space-x-4">
              <a href="/admin/products" class="text-gray-500 hover:text-gray-700 text-sm font-medium">Back to Products</a>
            </div>
          </div>
        </div>
      </div>

      <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="bg-white shadow rounded-lg">
          <div class="px-6 py-4 border-b border-gray-200">
            <h3 class="text-lg font-medium text-gray-900">Product Information</h3>
          </div>

          <form phx-submit="save" phx-change="validate" class="p-6 space-y-6">
            <!-- Product Name -->
            <div>
              <label for="name" class="block text-sm font-medium text-gray-700">Product Name</label>
              <input
                type="text"
                name="product[name]"
                id="name"
                value={@product["name"]}
                class={"mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm #{if @errors["name"], do: "border-red-300", else: ""}"}
                placeholder="Enter product name"
              />
              <%= if @errors["name"] do %>
                <p class="mt-1 text-sm text-red-600"><%= Enum.at(@errors["name"], 0) %></p>
              <% end %>
            </div>

            <!-- Description -->
            <div>
              <label for="description" class="block text-sm font-medium text-gray-700">Description</label>
              <textarea
                name="product[description]"
                id="description"
                rows="4"
                class={"mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm #{if @errors["description"], do: "border-red-300", else: ""}"}
                placeholder="Enter product description"
              ><%= @product["description"] %></textarea>
              <%= if @errors["description"] do %>
                <p class="mt-1 text-sm text-red-600"><%= Enum.at(@errors["description"], 0) %></p>
              <% end %>
            </div>

            <!-- Price and Stock -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label for="price" class="block text-sm font-medium text-gray-700">Price</label>
                <div class="mt-1 relative rounded-md shadow-sm">
                  <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <span class="text-gray-500 sm:text-sm">$</span>
                  </div>
                  <input
                    type="text"
                    name="product[price]"
                    id="price"
                    value={@product["price"]}
                    class={"block w-full pl-7 rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm #{if @errors["price"], do: "border-red-300", else: ""}"}
                    placeholder="0.00"
                  />
                </div>
                <%= if @errors["price"] do %>
                  <p class="mt-1 text-sm text-red-600"><%= Enum.at(@errors["price"], 0) %></p>
                <% end %>
              </div>

              <div>
                <label for="stock_quantity" class="block text-sm font-medium text-gray-700">Stock Quantity</label>
                <input
                  type="number"
                  name="product[stock_quantity]"
                  id="stock_quantity"
                  value={@product["stock_quantity"]}
                  min="0"
                  class={"mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm #{if @errors["stock_quantity"], do: "border-red-300", else: ""}"}
                  placeholder="0"
                />
                <%= if @errors["stock_quantity"] do %>
                  <p class="mt-1 text-sm text-red-600"><%= Enum.at(@errors["stock_quantity"], 0) %></p>
                <% end %>
              </div>
            </div>

            <!-- Category and Status -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label for="category" class="block text-sm font-medium text-gray-700">Category</label>
                <select
                  name="product[category]"
                  id="category"
                  class={"mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm #{if @errors["category"], do: "border-red-300", else: ""}"}
                >
                  <option value="" selected={@product["category"] == ""}>Select a category</option>
                  <option value="electronics" selected={@product["category"] == "electronics"}>Electronics</option>
                  <option value="clothing" selected={@product["category"] == "clothing"}>Clothing</option>
                  <option value="books" selected={@product["category"] == "books"}>Books</option>
                  <option value="home" selected={@product["category"] == "home"}>Home & Garden</option>
                  <option value="sports" selected={@product["category"] == "sports"}>Sports</option>
                </select>
                <%= if @errors["category"] do %>
                  <p class="mt-1 text-sm text-red-600"><%= Enum.at(@errors["category"], 0) %></p>
                <% end %>
              </div>

              <div>
                <label for="status" class="block text-sm font-medium text-gray-700">Status</label>
                <select
                  name="product[status]"
                  id="status"
                  class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
                >
                  <option value="active" selected={@product["status"] == "active"}>Active</option>
                  <option value="inactive" selected={@product["status"] == "inactive"}>Inactive</option>
                  <option value="draft" selected={@product["status"] == "draft"}>Draft</option>
                </select>
              </div>
            </div>

            <!-- Image URL -->
            <div>
              <label for="image_url" class="block text-sm font-medium text-gray-700">Image URL</label>
              <input
                type="url"
                name="product[image_url]"
                id="image_url"
                value={@product["image_url"]}
                class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
                placeholder="https://example.com/image.jpg"
              />
              <p class="mt-1 text-sm text-gray-500">Enter a valid image URL for the product</p>
            </div>

            <!-- Form Actions -->
            <div class="flex justify-end space-x-3 pt-6 border-t border-gray-200">
              <a
                href="/admin/products"
                class="bg-white py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              >
                Cancel
              </a>
              <button
                type="submit"
                class="bg-blue-600 py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              >
                Update Product
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
    """
  end
end
