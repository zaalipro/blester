defmodule BlesterWeb.BlogLive.EditComment do
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
  def mount(%{"id" => _id, "comment_id" => comment_id}, session, socket) do
    user_id = session["user_id"]
    case Accounts.get_comment(comment_id) do
      {:ok, comment} ->
        {:ok,
         socket
         |> assign(:comment, comment)
         |> assign(:page_title, "Edit Comment")
         |> assign(:current_user_id, user_id)}
      {:error, _} ->
        {:ok,
         socket
         |> put_flash(:error, "Comment not found")
         |> push_navigate(to: "/blog")}
    end
  end

  @impl true
  def handle_params(%{"id" => post_id, "comment_id" => comment_id}, _url, socket) do
    case Accounts.get_post(post_id) do
      {:ok, post} ->
        case Accounts.get_comment(comment_id) do
          {:ok, comment} ->
            user = current_user(socket)
            if user && comment.author_id == user.id do
              {:noreply,
               assign(socket,
                 comment: comment,
                 post: post,
                 page_title: "Edit Comment"
               )}
            else
              {:noreply,
               socket
               |> put_flash(:error, "Not authorized to edit this comment.")
               |> push_navigate(to: "/blog/#{post.id}")}
            end
          {:error, _} ->
            {:noreply,
             socket
             |> put_flash(:error, "Comment not found.")
             |> push_navigate(to: "/blog/#{post.id}")}
        end
      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Post not found.")
         |> push_navigate(to: "/blog")}
    end
  end

  @impl true
  def handle_event("save", %{"comment" => comment_params}, socket) do
    comment = socket.assigns.comment

    case Accounts.update_comment(comment.id, comment_params) do
      {:ok, _updated_comment} ->
        {:noreply,
         socket
         |> put_flash(:info, "Comment updated successfully.")
         |> push_navigate(to: "/blog/#{socket.assigns.post.id}")}

      {:error, changeset} ->
        {:noreply,
         assign(socket,
           comment: Map.merge(comment, comment_params),
           errors: format_errors(changeset)
         )}
    end
  end

  @impl true
  def handle_event("validate", %{"comment" => comment_params}, socket) do
    {:noreply, assign(socket, comment: Map.merge(socket.assigns.comment, comment_params))}
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
