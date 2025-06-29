defmodule BlesterWeb.ShopLive.Index do
  use BlesterWeb, :live_view
  import BlesterWeb.LiveValidations
  alias Blester.Accounts

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]
    cart_count = if user_id, do: Accounts.get_cart_count(user_id), else: 0
    current_user = case user_id do
      nil -> nil
      id -> case Accounts.get_user(id) do
        {:ok, user} -> user
        _ -> nil
      end
    end

    # Get products with pagination
    page = String.to_integer(Map.get(_params, "page", "1"))
    per_page = 12
    offset = (page - 1) * per_page

    # Get category filter
    category = Map.get(_params, "category", "")
    search = Map.get(_params, "search", "")

    # Get categories for filter dropdown
    categories = case Accounts.get_categories() do
      {:ok, cats} -> cats
      _ -> []
    end

    # Get products using the paginated function
    case Accounts.list_products_paginated(per_page, offset, search, category) do
      {:ok, {products, total_count}} ->
        total_pages = ceil(total_count / per_page)
        {:ok, assign(socket,
          products: products,
          current_page: page,
          page: page,
          per_page: per_page,
          total_pages: total_pages,
          total_count: total_count,
          category: category,
          search: search,
          categories: categories,
          quick_view_product: nil,
          current_user_id: user_id,
          current_user: current_user,
          cart_count: cart_count
        )}
      _ ->
        {:ok, assign(socket,
          products: [],
          current_page: page,
          page: page,
          per_page: per_page,
          total_pages: 0,
          total_count: 0,
          category: category,
          search: search,
          categories: categories,
          quick_view_product: nil,
          current_user_id: user_id,
          current_user: current_user,
          cart_count: cart_count
        )}
    end
  end

  @impl true
  def handle_params(%{"page" => page} = params, _url, socket) do
    page_num = String.to_integer(page)
    per_page = socket.assigns.per_page
    offset = (page_num - 1) * per_page

    category = Map.get(params, "category", socket.assigns.category)
    search = Map.get(params, "search", socket.assigns.search)

    case Accounts.list_products_paginated(per_page, offset, search, category) do
      {:ok, {products, total_count}} ->
        total_pages = ceil(total_count / per_page)
        {:noreply, assign(socket,
          products: products,
          current_page: page_num,
          page: page_num,
          total_pages: total_pages,
          total_count: total_count,
          category: category,
          search: search
        )}
      _ ->
        {:noreply, assign(socket,
          products: [],
          current_page: page_num,
          page: page_num,
          total_pages: 0,
          total_count: 0,
          category: category,
          search: search
        )}
    end
  end

  @impl true
  def handle_params(_params, _url, socket), do: {:noreply, socket}

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    {:noreply, push_patch(socket, to: "/shop?search=#{search}&category=#{socket.assigns.category}")}
  end

  @impl true
  def handle_event("filter-category", %{"category" => category}, socket) do
    {:noreply, push_patch(socket, to: "/shop?search=#{socket.assigns.search}&category=#{category}")}
  end

  @impl true
  def handle_event("add-to-cart", %{"product-id" => product_id}, socket) do
    case socket.assigns.current_user_id do
      nil ->
        {:noreply, put_flash(socket, :error, "Please log in to add items to cart")}
      user_id ->
        case Accounts.add_to_cart(user_id, product_id, 1) do
          {:ok, _cart_item} ->
            cart_count = Accounts.get_cart_count(user_id)
            {:noreply, assign(socket, cart_count: cart_count) |> put_flash(:info, "Product added to cart!")}
          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to add product to cart")}
        end
    end
  end

  @impl true
  def handle_event("quick-view", %{"product-id" => product_id}, socket) do
    case Accounts.get_product(product_id) do
      {:ok, product} ->
        {:noreply, assign(socket, quick_view_product: product)}
      _ ->
        {:noreply, put_flash(socket, :error, "Product not found")}
    end
  end

  @impl true
  def handle_event("close-quick-view", _params, socket) do
    {:noreply, assign(socket, quick_view_product: nil)}
  end

  @impl true
  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end

  # Helper functions
  defp format_price(price) do
    Decimal.to_string(price)
  end

  defp build_pagination_url(page, search, category) do
    params = []
    params = if search != "", do: params ++ ["search=#{search}"], else: params
    params = if category != "", do: params ++ ["category=#{category}"], else: params
    params = params ++ ["page=#{page}"]

    case params do
      [] -> "/shop"
      _ -> "/shop?#{Enum.join(params, "&")}"
    end
  end

  defp total_pages(total_count, per_page) do
    ceil(total_count / per_page)
  end
end
