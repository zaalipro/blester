defmodule BlesterWeb.ShopLive.Index do
  use BlesterWeb, :live_view
  alias Blester.Accounts

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]
    {:ok, assign(socket,
      products: [],
      total_count: 0,
      page: 1,
      per_page: 8,
      search: "",
      category: "",
      categories: [],
      loading: false,
      quick_view_product: nil,
      current_user_id: user_id
    )}
  end

  @impl true
  def handle_params(%{"page" => page} = params, _url, socket) do
    page = String.to_integer(page)
    category = Map.get(params, "category", "")
    search = Map.get(params, "search", "")
    {:noreply, assign(socket, page: page, category: category, search: search) |> load_products()}
  end

  @impl true
  def handle_params(%{"category" => category} = params, _url, socket) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    search = Map.get(params, "search", "")
    {:noreply, assign(socket, page: page, category: category, search: search) |> load_products()}
  end

  @impl true
  def handle_params(%{"search" => search} = params, _url, socket) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    category = Map.get(params, "category", "")
    {:noreply, assign(socket, page: page, category: category, search: search) |> load_products()}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket |> assign(page: 1, category: "", search: "") |> load_products()}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    category_param = if socket.assigns.category != "", do: "&category=#{socket.assigns.category}", else: ""
    search_param = if search != "", do: "search=#{search}", else: ""

    url = case {search_param, category_param} do
      {"", ""} -> "/shop"
      {"", _} -> "/shop?#{category_param}"
      {_, ""} -> "/shop?#{search_param}"
      {_, _} -> "/shop?#{search_param}#{category_param}"
    end

    {:noreply, push_patch(socket, to: url)}
  end

  @impl true
  def handle_event("filter-category", %{"category" => category}, socket) do
    IO.inspect("Filter category event triggered with: #{category}")
    if category == "" do
      {:noreply, push_patch(socket, to: "/shop")}
    else
      {:noreply, push_patch(socket, to: "/shop?category=#{category}")}
    end
  end

  @impl true
  def handle_event("add-to-cart", %{"product-id" => product_id}, socket) do
    case socket.assigns.current_user_id do
      nil ->
        {:noreply, push_navigate(socket, to: "/login")}
      user_id ->
        case Accounts.add_to_cart(user_id, product_id) do
          {:ok, _cart_item} ->
            {:noreply, socket |> put_flash(:info, "Product added to cart!")}
          {:error, _changeset} ->
            {:noreply, socket |> put_flash(:error, "Failed to add product to cart")}
        end
    end
  end

  @impl true
  def handle_event("quick-view", %{"product-id" => product_id}, socket) do
    case Accounts.get_product(product_id) do
      {:ok, product} ->
        {:noreply, assign(socket, quick_view_product: product)}
      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("close-quick-view", _params, socket) do
    {:noreply, assign(socket, quick_view_product: nil)}
  end

  defp load_products(socket) do
    offset = (socket.assigns.page - 1) * socket.assigns.per_page

    case Accounts.list_products_paginated(
      socket.assigns.per_page,
      offset,
      socket.assigns.search,
      socket.assigns.category
    ) do
      {:ok, {products, total_count}} ->
        categories = Accounts.get_categories()
        assign(socket,
          products: products,
          total_count: total_count,
          categories: categories
        )
      {:error, _} ->
        assign(socket, products: [], total_count: 0, categories: [])
    end
  end

  defp total_pages(total_count, per_page) do
    ceil(total_count / per_page)
  end

  defp format_price(price) do
    Decimal.to_string(price, :normal)
  end

  defp build_pagination_url(page, search, category) do
    params = []
    params = if search != "", do: params ++ ["search=#{search}"], else: params
    params = if category != "", do: params ++ ["category=#{category}"], else: params
    params = params ++ ["page=#{page}"]

    "/shop?#{Enum.join(params, "&")}"
  end
end
