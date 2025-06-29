defmodule BlesterWeb.BlogLive.Edit do
  use BlesterWeb, :live_view
  import BlesterWeb.LiveValidations
  alias Blester.Accounts

  @impl true
  def mount(%{"id" => id}, session, socket) do
    user_id = session[:user_id]
    cart_count = if user_id, do: Accounts.get_cart_count(user_id), else: 0
    current_user = case user_id do
      nil -> nil
      id -> case Accounts.get_user(id) do
        {:ok, user} -> user
        _ -> nil
      end
    end

    case user_id do
      nil ->
        {:ok, push_navigate(socket, to: "/login")}
      user_id ->
        case Accounts.get_post(id) do
          {:ok, post} ->
            if post.author_id == user_id do
              post_map = %{
                "title" => post.title,
                "content" => post.content
              }
              {:ok, assign(socket, post: post_map, post_id: id, errors: %{}, current_user_id: user_id, current_user: current_user, cart_count: cart_count)}
            else
              {:ok, push_navigate(socket, to: "/blog")}
            end
          {:error, _} ->
            {:ok, push_navigate(socket, to: "/blog")}
        end
    end
  end

  @impl true
  def handle_event("save", %{"post" => post_params}, socket) do
    case socket.assigns.current_user_id do
      nil ->
        {:noreply, push_navigate(socket, to: "/login")}
      user_id ->
        case Accounts.update_post(socket.assigns.post_id, post_params) do
          {:ok, post} ->
            {:noreply, add_flash_timer(socket, :info, "Post updated successfully") |> push_navigate(to: "/blog/#{post.id}")}
          {:error, changeset} ->
            errors = format_errors(changeset.errors)
            {:noreply, assign(socket, errors: errors) |> add_flash_timer(:error, "Failed to update post")}
        end
    end
  end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    errors = validate_post(post_params)
    {:noreply, assign(socket, post: post_params, errors: errors)}
  end

  @impl true
  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end

  defp current_user(socket) do
    case socket.assigns.current_user_id do
      nil -> nil
      user_id -> case Accounts.get_user(user_id) do
        {:ok, user} -> user
        _ -> nil
      end
    end
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <div class="max-w-4xl mx-auto">
        <div class="mb-8">
          <a href={"/blog/#{@post_id}"} class="text-blue-600 hover:text-blue-800">
            ← Back to Post
          </a>
        </div>

        <div class="bg-white rounded-lg shadow-md p-8">
          <h1 class="text-3xl font-bold text-gray-900 mb-6">Edit Post</h1>

          <form phx-change="validate" phx-submit="save" class="space-y-6">
            <div>
              <label for="title" class="block text-sm font-medium text-gray-700 mb-2">
                Title
              </label>
              <input
                type="text"
                name="post[title]"
                id="title"
                value={@post["title"]}
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="Enter post title..."
                required
              />
              <%= if @errors[:title] do %>
                <p class="mt-1 text-sm text-red-600"><%= @errors[:title] %></p>
              <% end %>
            </div>

            <div>
              <label for="content" class="block text-sm font-medium text-gray-700 mb-2">
                Content
              </label>
              <textarea
                name="post[content]"
                id="content"
                rows="12"
                value={@post["content"]}
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="Write your post content here..."
                required
              ></textarea>
              <%= if @errors[:content] do %>
                <p class="mt-1 text-sm text-red-600"><%= @errors[:content] %></p>
              <% end %>
            </div>

            <div class="flex justify-end space-x-4">
              <a href={"/blog/#{@post_id}"} class="btn btn-secondary">
                Cancel
              </a>
              <button type="submit" class="btn btn-primary">
                Update Post
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
    """
  end
end
