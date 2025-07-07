defmodule BlesterWeb.BlogLive.EditComment do
  use BlesterWeb, :live_view
  import BlesterWeb.LiveValidations
  alias BlesterWeb.LiveView.Authentication
  import BlesterWeb.LiveView.Authentication, only: [with_auth: 2]

  @impl true
  def mount(%{"id" => post_id, "comment_id" => comment_id}, session, socket) do
    Authentication.mount_authenticated(%{"id" => post_id, "comment_id" => comment_id}, session, socket, fn _params, socket ->
      case {Blester.Blog.get_post(post_id), Blester.Blog.get_comment(comment_id)} do
        {{:ok, post}, {:ok, comment}} ->
          if comment.author_id == socket.assigns.current_user.id do
            # Convert Ash struct to map with string keys for template access
            comment_map = %{
              "content" => Map.get(comment, :content)
            }
            {:ok, assign(socket, comment: comment_map, comment_id: comment_id, post_id: post_id, post: post, errors: %{})}
          else
            {:ok, push_navigate(socket, to: "/blog/#{post_id}")}
          end
        _ ->
          {:ok, push_navigate(socket, to: "/blog/#{post_id}")}
      end
    end)
  end

  @impl true
  def handle_event("save", %{"comment" => comment_params}, socket) do
    with_auth socket do
      case Blester.Blog.update_comment(socket.assigns.comment_id, comment_params) do
        {:ok, _comment} ->
          {:noreply, add_flash_timer(socket, :info, "Comment updated successfully") |> push_navigate(to: "/blog/#{socket.assigns.post_id}")}
        {:error, changeset} ->
          errors = format_errors(changeset.errors)
          {:noreply, assign(socket, errors: errors) |> add_flash_timer(:error, "Failed to update comment")}
      end
    end
  end

  @impl true
  def handle_event("validate", %{"comment" => comment_params}, socket) do
    errors = validate_comment(comment_params)
    # Merge the original comment data with the new params to preserve existing content
    updated_comment = Map.merge(socket.assigns.comment, comment_params)
    {:noreply, assign(socket, comment: updated_comment, errors: errors)}
  end

  @impl true
  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end
end
