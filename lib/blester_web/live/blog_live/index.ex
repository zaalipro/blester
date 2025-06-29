defmodule BlesterWeb.BlogLive.Index do
  use BlesterWeb, :live_view
  import BlesterWeb.LiveValidations
  alias Blester.Accounts

  @impl true
  def mount(_params, session, socket) do
    # Debug: Log session and assigns
    IO.inspect(session, label: "Session in BlogLive.Index")

    user_id = session[:user_id]
    IO.inspect(user_id, label: "User ID from session")

    cart_count = if user_id, do: Accounts.get_cart_count(user_id), else: 0
    current_user = case user_id do
      nil -> nil
      id -> case Accounts.get_user(id) do
        {:ok, user} -> user
        _ -> nil
      end
    end

    IO.inspect(current_user, label: "Current user")

    # Get posts with pagination
    page = String.to_integer(Map.get(_params, "page", "1"))
    per_page = 10
    offset = (page - 1) * per_page

    case Accounts.list_posts_paginated(per_page, offset) do
      {:ok, {posts, total_count}} ->
        total_pages = ceil(total_count / per_page)
        socket = assign(socket, posts: posts, errors: %{}, current_user_id: user_id, current_user: current_user, cart_count: cart_count, total_pages: total_pages, total_count: total_count, current_page: page)
        IO.inspect(socket.assigns, label: "Socket assigns after mount")
        {:ok, socket}
      _ ->
        socket = assign(socket, posts: [], errors: %{}, current_user_id: user_id, current_user: current_user, cart_count: cart_count, total_pages: 0, total_count: 0, current_page: page)
        IO.inspect(socket.assigns, label: "Socket assigns after mount (error case)")
        {:ok, socket}
    end
  end

  @impl true
  def handle_params(%{"page" => page}, _url, socket) do
    page = String.to_integer(page)
    {:noreply, load_posts(socket, page)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, load_posts(socket, 1)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    case Accounts.delete_post(id) do
      {:ok, _} ->
        posts = Enum.reject(socket.assigns.posts, fn post -> post.id == id end)
        {:noreply, assign(socket, posts: posts) |> add_flash_timer(:info, "Post deleted successfully")}
      {:error, _} ->
        {:noreply, add_flash_timer(socket, :error, "Failed to delete post")}
    end
  end

  @impl true
  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end

  defp load_posts(socket, page) do
    per_page = 10
    offset = (page - 1) * per_page
    case Accounts.list_posts_paginated(per_page, offset) do
      {:ok, {posts, total_count}} ->
        total_pages = ceil(total_count / per_page)
        assign(socket, posts: posts, total_count: total_count, current_page: page, total_pages: total_pages)
      {:error, _} ->
        assign(socket, posts: [], total_count: 0, current_page: page, total_pages: 0)
    end
  end

  defp current_user(socket) do
    case socket.assigns.current_user_id do
      nil -> nil
      user_id -> case Accounts.get_user(user_id) do
        {:ok, user} -> user
        _ -> nil
      end
    end
  end
end
