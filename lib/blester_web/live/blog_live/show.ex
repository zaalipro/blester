defmodule BlesterWeb.BlogLive.Show do
  use BlesterWeb, :live_view
  alias Blester.Blog
  import BlesterWeb.LiveView.Authentication, only: [with_auth: 2]
  import BlesterWeb.LiveValidations, only: [add_flash_timer: 3, format_errors: 1]

  @impl true
  def mount(%{"id" => id}, session, socket) do
    # For public posts, we don't require authentication but still want user info if available
    user_id = session["user_id"]
    cart_count = if user_id, do: Blester.Shop.get_cart_count(user_id), else: 0
    current_user = case user_id do
      nil -> nil
      id -> case Blester.Accounts.get_user(id) do
        {:ok, user} -> user
        _ -> nil
      end
    end

    case Blester.Blog.get_post(id) do
      {:ok, post} ->
        {:ok, assign(socket, post: post, comment_content: "", errors: %{}, current_user_id: user_id, current_user: current_user, cart_count: cart_count)}
      {:error, _} ->
        {:ok, push_navigate(socket, to: "/blog")}
    end
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    case Blester.Blog.get_post(id) do
      {:ok, post} ->
        case Blester.Blog.get_comments_for_post(post.id) do
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
  def handle_event("create-comment", %{"comment" => comment_params}, socket) do
    with_auth socket do
      comment_params = Map.put(comment_params, "author_id", socket.assigns.current_user_id)
      comment_params = Map.put(comment_params, "post_id", socket.assigns.post.id)

      case Blester.Blog.create_comment(comment_params) do
        {:ok, _comment} ->
          # Reload the post and comments to get updated comments
          case Blester.Blog.get_post(socket.assigns.post.id) do
            {:ok, updated_post} ->
              case Blester.Blog.get_comments_for_post(updated_post.id) do
                {:ok, comments} ->
                  {:noreply,
                    socket
                    |> assign(post: updated_post, comments: comments, comment_content: "")
                    |> put_flash(:info, "Comment added successfully!")}
                {:error, _} ->
                  {:noreply, put_flash(socket, :error, "Failed to reload comments")}
              end
            {:error, _} ->
              {:noreply, put_flash(socket, :error, "Failed to reload post")}
          end
        {:error, changeset} ->
          errors = format_errors(changeset.errors)
          {:noreply, assign(socket, errors: errors) |> put_flash(:error, "Failed to add comment")}
      end
    end
  end

  @impl true
  def handle_event("delete-comment", %{"comment-id" => comment_id}, socket) do
    with_auth socket do
      case Blester.Blog.get_comment(comment_id) do
        {:ok, comment} ->
          if comment.author_id == socket.assigns.current_user_id do
            case Blester.Blog.delete_comment(comment_id) do
              {:ok, _} ->
                # Reload the post to get updated comments
                case Blester.Blog.get_post(socket.assigns.post.id) do
                  {:ok, updated_post} ->
                    {:noreply, assign(socket, post: updated_post) |> add_flash_timer(:info, "Comment deleted successfully")}
                  {:error, _} ->
                    {:noreply, add_flash_timer(socket, :error, "Failed to reload post")}
                end
              {:error, _} ->
                {:noreply, add_flash_timer(socket, :error, "Failed to delete comment")}
            end
          else
            {:noreply, add_flash_timer(socket, :error, "Not authorized to delete this comment")}
          end
        {:error, _} ->
          {:noreply, add_flash_timer(socket, :error, "Comment not found")}
      end
    end
  end

  @impl true
  def handle_event("delete_post", %{"id" => id}, socket) do
    with_auth socket do
      post = socket.assigns.post
      user = socket.assigns.current_user
      if post && user && post.author_id == user.id do
        case Blester.Blog.delete_post(id) do
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

  @impl true
  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end
end
