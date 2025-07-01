defmodule BlesterWeb.AdminLive.Users do
  use BlesterWeb, :live_view
  import BlesterWeb.LiveValidations
  alias Blester.Accounts

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]
    cart_count = if user_id, do: Accounts.get_cart_count(user_id), else: 0

    case user_id do
      nil ->
        {:ok, push_navigate(socket, to: "/login")}
      user_id ->
        case Accounts.get_user(user_id) do
          {:ok, user} when not is_nil(user) ->
            if user.role == "admin" do
              {:ok, assign(socket,
                current_user: user,
                current_user_id: user_id,
                cart_count: cart_count,
                users: [],
                search: "",
                role: "all",
                page: 1,
                per_page: 10,
                total_count: 0,
                total_pages: 0
              ) |> load_users()}
            else
              {:ok, push_navigate(socket, to: "/")}
            end
          _ ->
            {:ok, push_navigate(socket, to: "/login")}
        end
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    search = Map.get(params, "search", "")
    role = Map.get(params, "role", "all")

    {:noreply, assign(socket, page: page, search: search, role: role) |> load_users()}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    {:noreply, push_patch(socket, to: "/admin/users?search=#{search}&role=#{socket.assigns.role}")}
  end

  @impl true
  def handle_event("filter-role", %{"role" => role}, socket) do
    {:noreply, push_patch(socket, to: "/admin/users?search=#{socket.assigns.search}&role=#{role}")}
  end

  @impl true
  def handle_event("update-role", %{"id" => id, "role" => role}, socket) do
    case Accounts.update_user_role(id, role) do
      {:ok, _user} ->
        {:noreply, load_users(socket) |> add_flash_timer(:info, "User role updated successfully")}
      {:error, _} ->
        {:noreply, add_flash_timer(socket, :error, "Failed to update user role")}
    end
  end

  @impl true
  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end

  defp load_users(socket) do
    offset = (socket.assigns.page - 1) * socket.assigns.per_page

    case Accounts.list_users_paginated(
      socket.assigns.per_page,
      offset,
      socket.assigns.search,
      socket.assigns.role
    ) do
      {:ok, {users, total_count}} ->
        total_pages = ceil(total_count / socket.assigns.per_page)
        assign(socket, users: users, total_count: total_count, total_pages: total_pages)
      {:error, _} ->
        assign(socket, users: [], total_count: 0, total_pages: 0)
    end
  end

  defp get_role_color(role) do
    case role do
      "admin" -> "bg-purple-100 text-purple-800"
      "user" -> "bg-green-100 text-green-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <!-- Admin Header -->
      <div class="bg-white shadow-sm border-b border-gray-200">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex justify-between items-center py-6">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <h1 class="text-2xl font-bold text-gray-900">User Management</h1>
              </div>
            </div>
            <div class="flex items-center space-x-4">
              <a href="/admin/dashboard" class="text-gray-500 hover:text-gray-700 text-sm font-medium">Dashboard</a>
            </div>
          </div>
        </div>
      </div>

      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <!-- Filters -->
        <div class="bg-white shadow rounded-lg mb-6">
          <div class="p-6">
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <!-- Search -->
              <div>
                <label for="search" class="block text-sm font-medium text-gray-700 mb-2">Search Users</label>
                <form phx-change="search" class="relative">
                  <input
                    type="text"
                    name="search"
                    id="search"
                    value={@search}
                    placeholder="Search by name, email..."
                    class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                  <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <svg class="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
                    </svg>
                  </div>
                </form>
              </div>

              <!-- Role Filter -->
              <div>
                <label for="role" class="block text-sm font-medium text-gray-700 mb-2">Role</label>
                <form phx-change="filter-role">
                  <select
                    name="role"
                    id="role"
                    value={@role}
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  >
                    <option value="all">All Roles</option>
                    <option value="admin">Admin</option>
                    <option value="user">User</option>
                  </select>
                </form>
              </div>

              <!-- Results Count -->
              <div class="flex items-end">
                <p class="text-sm text-gray-500">
                  <%= @total_count %> users found
                </p>
              </div>
            </div>
          </div>
        </div>

        <!-- Users Table -->
        <div class="bg-white shadow rounded-lg overflow-hidden">
          <%= if Enum.empty?(@users) do %>
            <div class="text-center py-12">
              <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z"></path>
              </svg>
              <h3 class="mt-2 text-sm font-medium text-gray-900">No users found</h3>
              <p class="mt-1 text-sm text-gray-500">Users will appear here when they register.</p>
            </div>
          <% else %>
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Role</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Joined</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <%= for user <- @users do %>
                    <tr class="hover:bg-gray-50">
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="flex items-center">
                          <div class="flex-shrink-0 h-10 w-10">
                            <div class="h-10 w-10 rounded-full bg-gray-300 flex items-center justify-center">
                              <span class="text-sm font-medium text-gray-700">
                                <%= String.first(user.first_name) %><%= String.first(user.last_name) %>
                              </span>
                            </div>
                          </div>
                          <div class="ml-4">
                            <div class="text-sm font-medium text-gray-900">
                              <%= user.first_name %> <%= user.last_name %>
                            </div>
                          </div>
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        <%= user.email %>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <span class={"inline-flex px-2 py-1 text-xs font-semibold rounded-full #{get_role_color(user.role)}"}>
                          <%= String.capitalize(user.role) %>
                        </span>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        <%= Calendar.strftime(user.inserted_at, "%b %d, %Y") %>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                        <select
                          phx-change="update-role"
                          phx-value-id={user.id}
                          class="text-xs border border-gray-300 rounded px-2 py-1"
                        >
                          <option value="">Change Role</option>
                          <option value="user">User</option>
                          <option value="admin">Admin</option>
                        </select>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>

            <!-- Pagination -->
            <%= if @total_pages > 1 do %>
              <div class="bg-white px-4 py-3 flex items-center justify-between border-t border-gray-200 sm:px-6">
                <div class="flex-1 flex justify-between sm:hidden">
                  <%= if @page > 1 do %>
                    <a href={"/admin/users?page=#{@page - 1}&search=#{@search}&role=#{@role}"} class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
                      Previous
                    </a>
                  <% end %>
                  <%= if @page < @total_pages do %>
                    <a href={"/admin/users?page=#{@page + 1}&search=#{@search}&role=#{@role}"} class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
                      Next
                    </a>
                  <% end %>
                </div>
                <div class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
                  <div>
                    <p class="text-sm text-gray-700">
                      Showing <span class="font-medium"><%= (@page - 1) * @per_page + 1 %></span> to <span class="font-medium"><%= min(@page * @per_page, @total_count) %></span> of <span class="font-medium"><%= @total_count %></span> results
                    </p>
                  </div>
                  <div>
                    <nav class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px">
                      <%= if @page > 1 do %>
                        <a href={"/admin/users?page=#{@page - 1}&search=#{@search}&role=#{@role}"} class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50">
                          <span class="sr-only">Previous</span>
                          <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
                          </svg>
                        </a>
                      <% end %>

                      <%= for page_num <- max(1, @page - 2)..min(@total_pages, @page + 2) do %>
                        <a
                          href={"/admin/users?page=#{page_num}&search=#{@search}&role=#{@role}"}
                          class={"relative inline-flex items-center px-4 py-2 border text-sm font-medium #{if page_num == @page, do: "z-10 bg-blue-50 border-blue-500 text-blue-600", else: "bg-white border-gray-300 text-gray-500 hover:bg-gray-50"}"}
                        >
                          <%= page_num %>
                        </a>
                      <% end %>

                      <%= if @page < @total_pages do %>
                        <a href={"/admin/users?page=#{@page + 1}&search=#{@search}&role=#{@role}"} class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50">
                          <span class="sr-only">Next</span>
                          <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
                          </svg>
                        </a>
                      <% end %>
                    </nav>
                  </div>
                </div>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
