defmodule BlesterWeb.BlogLive.Edit do
  use BlesterWeb, :live_view
  import BlesterWeb.LiveValidations
  alias Blester.Accounts
  alias BlesterWeb.LiveView.Authentication
  import BlesterWeb.LiveView.Authentication, only: [with_auth: 2]

  @impl true
  def mount(%{"id" => id}, session, socket) do
    Authentication.mount_authenticated(%{"id" => id}, session, socket, fn _params, socket ->
      case Accounts.get_post(id) do
        {:ok, post} ->
          if post.author_id == socket.assigns.current_user.id do
            # Convert Ash struct to map with string keys for template access
            post_map = %{
              "title" => Map.get(post, :title),
              "content" => Map.get(post, :content)
            }
            {:ok, assign(socket, post: post_map, post_id: id, errors: %{})}
          else
            {:ok, push_navigate(socket, to: "/blog")}
          end
        {:error, _} ->
          {:ok, push_navigate(socket, to: "/blog")}
      end
    end)
  end

  @impl true
  def handle_event("save", %{"post" => post_params}, socket) do
    with_auth socket do
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
    # Merge the original post data with the new params to preserve existing content
    updated_post = Map.merge(socket.assigns.post, post_params)
    {:noreply, assign(socket, post: updated_post, errors: errors)}
  end

  @impl true
  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end
end
