defmodule BlesterWeb.BlogLive.Show do
  use BlesterWeb, :live_view

  alias Blester.Accounts

  @impl true
  def mount(%{"id" => id}, session, socket) do
    # Get user_id from session (which is populated by the SetCurrentUser plug)
    user_id = session["user_id"] || session[:user_id]
    case Accounts.get_post(id) do
      {:ok, post} ->
        {:ok,
         socket
         |> assign(current_user_id: user_id)
         |> assign(:post, post)
         |> assign(:new_comment, %{content: ""})
         |> assign(:page_title, "Post: #{post.title}")}

      {:error, _} ->
        {:ok,
         socket
         |> assign(current_user_id: user_id)
         |> put_flash(:error, "Post not found")
         |> push_navigate(to: "/blog")}
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
    if socket.assigns.current_user_id do
      post = socket.assigns.post
      author_id = socket.assigns.current_user_id
      attrs = Map.merge(comment_params, %{"author_id" => author_id, "post_id" => post.id})

      case Accounts.create_comment(attrs) do
        {:ok, _comment} ->
          # Reload comments
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
    # Convert string keys to atom keys for the template
    new_comment = for {key, val} <- comment_params, into: %{} do
      {String.to_atom(key), val}
    end
    {:noreply, assign(socket, new_comment: new_comment)}
  end

  @impl true
  def handle_event("delete_comment", %{"id" => id}, socket) do
    comment = Enum.find(socket.assigns.comments, &(&1.id == id))

    if comment && comment.author_id == socket.assigns.current_user_id do
      case Accounts.delete_comment(id) do
        :ok ->
          # Reload comments
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
end
