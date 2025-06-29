defmodule BlesterWeb.BlogLive.EditComment do
  use BlesterWeb, :live_view

  alias Blester.Accounts

  @impl true
  def mount(_params, session, socket) do
    current_user_id = session["user_id"]
    {:ok, assign(socket, page_title: "Edit Comment", comment: nil, post: nil, errors: [], current_user_id: current_user_id)}
  end

  @impl true
  def handle_params(%{"id" => post_id, "comment_id" => comment_id}, _url, socket) do
    case Accounts.get_post(post_id) do
      {:ok, post} ->
        case Accounts.get_comment(comment_id) do
          {:ok, comment} ->
            if comment.author_id == socket.assigns.current_user_id do
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
