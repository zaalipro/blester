defmodule BlesterWeb.BlogLive.Edit do
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
    case Accounts.get_post(id) do
      {:ok, post} ->
        {:ok,
         socket
         |> assign(:post, post)
         |> assign(:page_title, "Edit Post")
         |> assign(:errors, %{})
         |> assign(:current_user_id, user_id)}
      {:error, _} ->
        {:ok,
         socket
         |> put_flash(:error, "Post not found")
         |> push_navigate(to: "/blog")}
    end
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    case Accounts.get_post(id) do
      {:ok, post} ->
        user = current_user(socket)
        if user && post.author_id == user.id do
          {:noreply,
           assign(socket,
             post: post,
             page_title: "Edit: #{post.title}",
             errors: %{}
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

    # Convert string keys to atom keys for Ash
    attrs = %{
      title: post_params["title"],
      content: post_params["content"]
    }

    case Accounts.update_post(post.id, attrs) do
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
