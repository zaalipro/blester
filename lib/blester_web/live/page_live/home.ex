defmodule BlesterWeb.PageLive.Home do
  use BlesterWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]
    cart_count = if user_id, do: Accounts.get_cart_count(user_id), else: 0
    {:ok, assign(socket, current_user_id: user_id, cart_count: cart_count, page_title: "Blester")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <div class="max-w-2xl mx-auto text-center">
        <h1 class="text-4xl font-bold text-gray-900 mb-4">Welcome to Blester</h1>
        <p class="text-xl text-gray-600 mb-8">Your new Phoenix application with Ash Framework</p>

        <%= if @current_user_id do %>
          <div class="space-y-4">
            <p class="text-lg text-gray-700 mb-4">You are logged in!</p>
            <div class="space-x-4">
              <a href="/blog" class="btn btn-primary inline-block">Blog</a>
              <a href="/logout" class="btn btn-secondary inline-block">Logout</a>
            </div>
          </div>
        <% else %>
        <div class="space-y-4">
          <a href="/register" class="btn btn-primary inline-block">Get Started</a>
          <a href="/blog" class="btn btn-secondary inline-block ml-4">Blog</a>
        </div>
        <% end %>
      </div>
    </div>
    """
  end
end
