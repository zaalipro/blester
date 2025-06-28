defmodule BlesterWeb.BlogController do
  use Phoenix.Controller, layouts: [html: {BlesterWeb.Layouts, :app}]
  import Plug.Conn
  import BlesterWeb.Gettext

  alias Blester.Accounts

  plug :require_authenticated_user when action in [:new_post, :create_post, :edit_post, :update_post, :delete_post, :create_comment, :edit_comment, :update_comment, :delete_comment]
  plug :load_post when action in [:show_post, :edit_post, :update_post, :delete_post, :create_comment, :edit_comment, :update_comment, :delete_comment]
  plug :load_comment when action in [:edit_comment, :update_comment, :delete_comment]

  def index(conn, params) do
    page = String.to_integer(params["page"] || "1")
    per_page = 10
    offset = (page - 1) * per_page

    case Accounts.list_posts_paginated(per_page, offset) do
      {:ok, {posts, total_count}} ->
        total_pages = ceil(total_count / per_page)
        render(conn, "index.html",
          posts: posts,
          current_page: page,
          total_pages: total_pages,
          total_count: total_count,
          per_page: per_page
        )
      {:error, _} ->
        render(conn, "index.html",
          posts: [],
          current_page: 1,
          total_pages: 1,
          total_count: 0,
          per_page: per_page
        )
    end
  end

  def show_post(conn, _params) do
    post = conn.assigns[:post]
    case Accounts.get_comments_for_post(post.id) do
      {:ok, comments} ->
        IO.inspect(comments, label: "[DEBUG] comments for post")
        render(conn, "show.html", post: post, comments: comments)
      {:error, _} ->
        render(conn, "show.html", post: post, comments: [])
    end
  end

  def new_post(conn, _params) do
    render(conn, "new.html")
  end

  def create_post(conn, %{"post" => post_params}) do
    author_id = conn.assigns[:current_user_id]
    attrs = Map.put(post_params, "author_id", author_id)
    case Accounts.create_post(attrs) do
      {:ok, post} ->
        conn |> put_flash(:info, "Post created!") |> redirect(to: "/blog/#{post.id}")
      {:error, changeset} ->
        conn |> put_flash(:error, "Failed to create post") |> render("new.html", changeset: changeset)
    end
  end

  def edit_post(conn, _params) do
    post = conn.assigns[:post]
    if post.author_id == conn.assigns[:current_user_id] do
      render(conn, "edit.html", post: post)
    else
      conn |> put_flash(:error, "Not authorized") |> redirect(to: "/blog/#{post.id}")
    end
  end

  def update_post(conn, %{"id" => id, "post" => post_params}) do
    post = conn.assigns[:post]
    if post.author_id == conn.assigns[:current_user_id] do
      case Accounts.update_post(id, post_params) do
        {:ok, post} ->
          conn |> put_flash(:info, "Post updated!") |> redirect(to: "/blog/#{post.id}")
        {:error, changeset} ->
          conn |> put_flash(:error, "Failed to update post") |> render("edit.html", post: post, changeset: changeset)
      end
    else
      conn |> put_flash(:error, "Not authorized") |> redirect(to: "/blog/#{post.id}")
    end
  end

  def delete_post(conn, %{"id" => id}) do
    post = conn.assigns[:post]
    if post.author_id == conn.assigns[:current_user_id] do
      Accounts.delete_post(id)
      conn |> put_flash(:info, "Post deleted!") |> redirect(to: "/blog")
    else
      conn |> put_flash(:error, "Not authorized") |> redirect(to: "/blog/#{post.id}")
    end
  end

  def create_comment(conn, %{"comment" => comment_params}) do
    post = conn.assigns[:post]
    author_id = conn.assigns[:current_user_id]
    attrs = Map.merge(comment_params, %{"author_id" => author_id, "post_id" => post.id})
    case Accounts.create_comment(attrs) do
      {:ok, _comment} ->
        conn |> put_flash(:info, "Comment added!") |> redirect(to: "/blog/#{post.id}")
      {:error, changeset} ->
        conn |> put_flash(:error, "Failed to add comment") |> redirect(to: "/blog/#{post.id}")
    end
  end

  def edit_comment(conn, _params) do
    comment = conn.assigns[:comment]
    post = conn.assigns[:post]
    if comment.author_id == conn.assigns[:current_user_id] do
      render(conn, "edit_comment.html", comment: comment, post: post)
    else
      conn |> put_flash(:error, "Not authorized") |> redirect(to: "/blog/#{post.id}")
    end
  end

  def update_comment(conn, %{"comment_id" => id, "comment" => comment_params}) do
    comment = conn.assigns[:comment]
    post = conn.assigns[:post]
    if comment.author_id == conn.assigns[:current_user_id] do
      case Accounts.update_comment(id, comment_params) do
        {:ok, _comment} ->
          conn |> put_flash(:info, "Comment updated!") |> redirect(to: "/blog/#{post.id}")
        {:error, changeset} ->
          conn |> put_flash(:error, "Failed to update comment") |> render("edit_comment.html", comment: comment, post: post, changeset: changeset)
      end
    else
      conn |> put_flash(:error, "Not authorized") |> redirect(to: "/blog/#{post.id}")
    end
  end

  def delete_comment(conn, %{"comment_id" => id}) do
    comment = conn.assigns[:comment]
    post = conn.assigns[:post]

    if is_nil(comment) do
      conn |> put_flash(:error, "Comment not found") |> redirect(to: "/blog/#{post.id}")
    else
      if comment.author_id == conn.assigns[:current_user_id] do
        case Accounts.delete_comment(id) do
          :ok ->
            conn |> put_flash(:info, "Comment deleted!") |> redirect(to: "/blog/#{post.id}")
          {:error, _} ->
            conn |> put_flash(:error, "Failed to delete comment") |> redirect(to: "/blog/#{post.id}")
        end
      else
        conn |> put_flash(:error, "Not authorized") |> redirect(to: "/blog/#{post.id}")
      end
    end
  end

  # Plugs
  defp require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user_id] do
      conn
    else
      conn |> put_flash(:error, "You must be logged in.") |> redirect(to: "/login") |> halt()
    end
  end

  defp load_post(conn, _opts) do
    id = conn.params["id"] || conn.params["post_id"]
    case Accounts.get_post(id) do
      {:ok, post} -> assign(conn, :post, post)
      _ -> conn |> put_flash(:error, "Post not found") |> redirect(to: "/blog") |> halt()
    end
  end

  defp load_comment(conn, _opts) do
    id = conn.params["comment_id"]
    case Accounts.get_comment(id) do
      {:ok, comment} -> assign(conn, :comment, comment)
      _ -> conn |> put_flash(:error, "Comment not found") |> redirect(to: "/blog") |> halt()
    end
  end
end
