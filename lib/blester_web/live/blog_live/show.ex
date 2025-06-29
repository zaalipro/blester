defmodule BlesterWeb.BlogLive.Show do
  use BlesterWeb, :live_view

  alias Blester.Accounts

  defp current_user(socket) do
    user_id = socket.assigns[:current_user_id]
    case user_id do
      nil -> nil
      id ->
        case Accounts.get_user(id) do
          {:ok, user} -> user
          _ -> nil
        end
    end
  end

  @impl true
  def mount(%{"id" => id}, session, socket) do
    user_id = session["user_id"]
    cart_count = if user_id, do: Accounts.get_cart_count(user_id), else: 0

    case Accounts.get_post(id) do
      {:ok, post} ->
        {:ok, assign(socket, post: post, comment_content: "", errors: %{}, current_user_id: user_id, cart_count: cart_count)}
      {:error, _} ->
        {:ok, push_navigate(socket, to: "/blog")}
    end
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    case Accounts.get_post(id) do
      {:ok, post} ->
        case Accounts.get_comments_for_post(post.id) do
          {:ok, comments} ->
            {:noreply,
             assign(socket,
               post: post,
               comments: comments,
               new_comment: %{content: ""},
               page_title: post.title
             )}
          {:error, _} ->
            {:noreply, assign(socket, post: post, comments: [], new_comment: %{content: ""}, page_title: post.title)}
        end
      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Post not found.")
         |> push_navigate(to: "/blog")}
    end
  end

  @impl true
  def handle_event("save_comment", %{"comment" => comment_params}, socket) do
    user = current_user(socket)
    if user do
      post = socket.assigns.post
      author_id = user.id
      attrs = Map.merge(comment_params, %{"author_id" => author_id, "post_id" => post.id})
      case Accounts.create_comment(attrs) do
        {:ok, _comment} ->
          case Accounts.get_comments_for_post(post.id) do
            {:ok, comments} ->
              {:noreply,
               socket
               |> assign(comments: comments, new_comment: %{content: ""})
               |> put_flash(:info, "Comment added!")}
            {:error, _} ->
              {:noreply, put_flash(socket, :error, "Failed to load comments.")}
          end
        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to add comment.")}
      end
    else
      {:noreply, put_flash(socket, :error, "You must be logged in to comment.")}
    end
  end

  @impl true
  def handle_event("validate_comment", %{"comment" => comment_params}, socket) do
    new_comment = for {key, val} <- comment_params, into: %{} do
      {String.to_atom(key), val}
    end
    {:noreply, assign(socket, new_comment: new_comment)}
  end

  @impl true
  def handle_event("delete_comment", %{"id" => id}, socket) do
    comment = Enum.find(socket.assigns.comments, &(&1.id == id))
    user = current_user(socket)
    if comment && user && comment.author_id == user.id do
      case Accounts.delete_comment(id) do
        :ok ->
          case Accounts.get_comments_for_post(socket.assigns.post.id) do
            {:ok, comments} ->
              {:noreply,
               socket
               |> assign(comments: comments)
               |> put_flash(:info, "Comment deleted!")}
            {:error, _} ->
              {:noreply, put_flash(socket, :error, "Failed to load comments.")}
          end
        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to delete comment.")}
      end
    else
      {:noreply, put_flash(socket, :error, "Not authorized to delete this comment.")}
    end
  end

  @impl true
  def handle_event("delete_post", %{"id" => id}, socket) do
    post = socket.assigns.post
    user = current_user(socket)
    if post && user && post.author_id == user.id do
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
end
