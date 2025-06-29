defmodule BlesterWeb.BlogLive.Index do
  use BlesterWeb, :live_view

  alias Blester.Accounts

  @impl true
  def mount(_params, session, socket) do
    current_user_id = session["user_id"]
    {:ok, assign(socket, page_title: "Blog", posts: [], current_page: 1, total_pages: 1, total_count: 0, per_page: 10, current_user_id: current_user_id)}
  end

  @impl true
  def handle_params(%{"page" => page}, _url, socket) do
    page = String.to_integer(page)
    load_posts(socket, page)
  end

  @impl true
  def handle_params(_params, _url, socket) do
    load_posts(socket, 1)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    post = Enum.find(socket.assigns.posts, &(&1.id == id))

    if post && post.author_id == socket.assigns.current_user_id do
      case Accounts.delete_post(id) do
        :ok ->
          {:noreply,
           socket
           |> put_flash(:info, "Post deleted successfully.")
           |> push_navigate(to: "/blog")}
        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to delete post.")}
      end
    else
      {:noreply, put_flash(socket, :error, "Not authorized to delete this post.")}
    end
  end

  defp load_posts(socket, page) do
    per_page = socket.assigns.per_page
    offset = (page - 1) * per_page

    case Accounts.list_posts_paginated(per_page, offset) do
      {:ok, {posts, total_count}} ->
        total_pages = ceil(total_count / per_page)
        {:noreply,
         assign(socket,
           posts: posts,
           current_page: page,
           total_pages: total_pages,
           total_count: total_count
         )}
      {:error, _} ->
        {:noreply,
         assign(socket,
           posts: [],
           current_page: 1,
           total_pages: 1,
           total_count: 0
         )}
    end
  end
end
