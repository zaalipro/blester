defmodule BlesterWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use BlesterWeb, :html

  embed_templates "page_html/*"

  def home(assigns) do
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
