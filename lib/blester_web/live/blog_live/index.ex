defmodule BlesterWeb.BlogLive.Index do
  use BlesterWeb, :live_view
  import BlesterWeb.LiveValidations
  alias Blester.Blog

  @impl true
  def mount(params, session, socket) do
    user_id = session["user_id"]
    cart_count = if user_id, do: Blester.Shop.get_cart_count(user_id), else: 0
    # Only use Accounts for user logic if needed
    current_user = case user_id do
      nil -> nil
      id -> case Blester.Accounts.get_user(id) do
        {:ok, user} -> user
        _ -> nil
      end
    end

    # Get posts with pagination and search
    page = String.to_integer(Map.get(params, "page", "1"))
    search = Map.get(params, "search", "")
    per_page = 10
    offset = (page - 1) * per_page

    case Blester.Blog.list_posts_paginated(per_page, offset, search) do
      {:ok, {posts, total_count}} ->
        total_pages = ceil(total_count / per_page)
        socket = assign(socket, posts: posts, errors: %{}, current_user_id: user_id, current_user: current_user, cart_count: cart_count, total_pages: total_pages, total_count: total_count, current_page: page, search: search)
        {:ok, socket}
      _ ->
        socket = assign(socket, posts: [], errors: %{}, current_user_id: user_id, current_user: current_user, cart_count: cart_count, total_pages: 0, total_count: 0, current_page: page, search: search)
        {:ok, socket}
    end
  end

  @impl true
  def handle_params(%{"page" => page} = params, _url, socket) do
    page = String.to_integer(page)
    search = Map.get(params, "search", socket.assigns.search)
    {:noreply, load_posts(socket, page, search)}
  end

  @impl true
  def handle_params(%{"search" => search} = params, _url, socket) do
    page = String.to_integer(Map.get(params, "page", "1"))
    {:noreply, load_posts(socket, page, search)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, load_posts(socket, 1, "")}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    {:noreply, push_patch(socket, to: "/blog?search=#{search}")}
  end

  @impl true
  def handle_event("delete_post", %{"id" => id}, socket) do
    case socket.assigns.current_user_id do
      nil ->
        {:noreply, push_navigate(socket, to: "/login")}
      user_id ->
        case Blester.Blog.get_post(id) do
          {:ok, post} ->
            if post.author_id == user_id do
              case Blester.Blog.delete_post(id) do
                :ok ->
                  case Blester.Blog.list_posts_paginated(10, 0, socket.assigns.search) do
                    {:ok, {posts, _total_count}} ->
                      {:noreply, assign(socket, posts: posts) |> add_flash_timer(:info, "Post deleted successfully")}
                    _ ->
                      {:noreply, add_flash_timer(socket, :error, "Failed to reload posts")}
                  end
                {:error, _} ->
                  {:noreply, add_flash_timer(socket, :error, "Failed to delete post")}
              end
            else
              {:noreply, add_flash_timer(socket, :error, "Not authorized to delete this post")}
            end
          {:error, _} ->
            {:noreply, add_flash_timer(socket, :error, "Post not found")}
        end
    end
  end

  defp load_posts(socket, page, search) do
    per_page = 10
    offset = (page - 1) * per_page
    case Blester.Blog.list_posts_paginated(per_page, offset, search) do
      {:ok, {posts, total_count}} ->
        total_pages = ceil(total_count / per_page)
        assign(socket, posts: posts, total_count: total_count, current_page: page, total_pages: total_pages, search: search)
      {:error, _} ->
        assign(socket, posts: [], total_count: 0, current_page: page, total_pages: 0, search: search)
    end
  end

  @impl true
  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end
end
