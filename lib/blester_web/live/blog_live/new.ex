defmodule BlesterWeb.BlogLive.New do
  use BlesterWeb, :live_view
  import BlesterWeb.LiveValidations
  alias Blester.Accounts
  alias BlesterWeb.LiveView.Authentication
  import BlesterWeb.LiveView.Authentication, only: [with_auth: 2]

  @impl true
  def mount(_params, session, socket) do
    Authentication.mount_authenticated(_params, session, socket, fn _params, socket ->
      {:ok, assign(socket, post: %{}, errors: %{})}
    end)
  end

  @impl true
  def handle_event("save", %{"post" => post_params}, socket) do
    with_auth socket do
      user_id = socket.assigns.current_user_id
      post_params = Map.put(post_params, "author_id", user_id)

      case Accounts.create_post(post_params) do
        {:ok, post} ->
          {:noreply, add_flash_timer(socket, :info, "Post created successfully") |> push_navigate(to: "/blog/#{post.id}")}
        {:error, changeset} ->
          errors = format_errors(changeset.errors)
          {:noreply, assign(socket, errors: errors) |> add_flash_timer(:error, "Failed to create post")}
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

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <div class="max-w-4xl mx-auto">
        <div class="mb-8">
          <a href="/blog" class="text-blue-600 hover:text-blue-800">
            ← Back to Blog
          </a>
        </div>

        <div class="bg-white rounded-lg shadow-md p-8">
          <h1 class="text-3xl font-bold text-gray-900 mb-6">Create New Post</h1>

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
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="Write your post content here..."
                required
              ><%= @post["content"] %></textarea>
              <%= if @errors[:content] do %>
                <p class="mt-1 text-sm text-red-600"><%= @errors[:content] %></p>
              <% end %>
            </div>

            <div class="flex justify-end space-x-4">
              <a href="/blog" class="btn btn-secondary">
                Cancel
              </a>
              <button type="submit" class="btn btn-primary">
                Create Post
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
    """
  end
end
