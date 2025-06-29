defmodule BlesterWeb.BlogLive.Edit do
  use BlesterWeb, :live_view

  alias Blester.Accounts

  @impl true
  def mount(%{"id" => id}, session, socket) do
    # Get user_id from session (which is populated by the SetCurrentUser plug)
    user_id = session["user_id"] || session[:user_id]
    case Accounts.get_post(id) do
      {:ok, post} ->
        if post.author_id == user_id do
          {:ok,
           socket
           |> assign(current_user_id: user_id)
           |> assign(:page_title, "Edit Post")
           |> assign(:post, post)}
        else
          {:ok,
           socket
           |> assign(current_user_id: user_id)
           |> put_flash(:error, "Not authorized to edit this post")
           |> push_navigate(to: "/blog")}
        end

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
        if post.author_id == socket.assigns.current_user_id do
          {:noreply,
           assign(socket,
             post: post,
             page_title: "Edit: #{post.title}"
           )}
        else
          {:noreply,
           socket
           |> put_flash(:error, "Not authorized to edit this post.")
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
  def handle_event("save", %{"post" => post_params}, socket) do
    post = socket.assigns.post

    case Accounts.update_post(post.id, post_params) do
      {:ok, updated_post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Post updated successfully.")
         |> push_navigate(to: "/blog/#{updated_post.id}")}

      {:error, changeset} ->
        {:noreply,
         assign(socket,
           post: Map.merge(post, post_params),
           errors: format_errors(changeset)
         )}
    end
  end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    {:noreply, assign(socket, post: Map.merge(socket.assigns.post, post_params))}
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
