defmodule BlesterWeb.BlogLive.New do
  use BlesterWeb, :live_view

  alias Blester.Accounts

  @impl true
  def mount(_params, session, socket) do
    current_user_id = session["user_id"]
    {:ok,
     assign(socket,
       page_title: "New Post",
       post: %{title: "", content: ""},
       errors: [],
       current_user_id: current_user_id
     )}
  end

  @impl true
  def handle_event("save", %{"post" => post_params}, socket) do
    author_id = socket.assigns.current_user_id
    attrs = Map.put(post_params, "author_id", author_id)

    case Accounts.create_post(attrs) do
      {:ok, post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Post created successfully.")
         |> push_navigate(to: "/blog/#{post.id}")}

      {:error, changeset} ->
        {:noreply,
         assign(socket,
           post: post_params,
           errors: format_errors(changeset)
         )}
    end
  end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    {:noreply, assign(socket, post: post_params)}
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
