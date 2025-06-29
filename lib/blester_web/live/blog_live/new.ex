defmodule BlesterWeb.BlogLive.New do
  use BlesterWeb, :live_view

  alias Blester.Accounts

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]
    cart_count = if user_id, do: Accounts.get_cart_count(user_id), else: 0
    case user_id do
      nil ->
        {:ok, push_navigate(socket, to: "/login")}
      user_id ->
        {:ok, assign(socket, post: %{}, errors: %{}, current_user_id: user_id, cart_count: cart_count)}
    end
  end

  @impl true
  def handle_event("save", %{"post" => post_params}, socket) do
    user = current_user(socket)
    author_id = user && user.id

    if author_id do
      # Convert string keys to atom keys for Ash
      attrs = %{
        title: post_params["title"],
        content: post_params["content"],
        author_id: author_id
      }

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
    else
      {:noreply,
       socket
       |> put_flash(:error, "You must be logged in to create a post.")
       |> push_navigate(to: "/login")}
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
end
