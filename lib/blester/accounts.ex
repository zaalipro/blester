defmodule Blester.Accounts do
  use Ash.Domain

  require Ash.Query

  resources do
    resource Blester.Accounts.User
    resource Blester.Accounts.Post
    resource Blester.Accounts.Comment
  end

  # In Ash 3.x, we can call Ash functions directly on resources

  def get_user_by_email(email) do
    Blester.Accounts.User
    |> Ash.Query.filter(email: email)
    |> Ash.read_one()
  end

  def create_user(attrs) do
    Blester.Accounts.User
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  # Blog functions
  def create_post(attrs) do
    Blester.Accounts.Post
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  def get_post(id) do
    Blester.Accounts.Post
    |> Ash.Query.filter(id: id)
    |> Ash.Query.load([:author, :comments])
    |> Ash.read_one()
  end

  def list_posts do
    Blester.Accounts.Post
    |> Ash.Query.load([:author, :comments])
    |> Ash.Query.sort(inserted_at: :desc)
    |> Ash.read()
  end

  def list_posts_paginated(limit, offset) do
    # Get total count
    total_count =
      Blester.Accounts.Post
      |> Ash.count()
      |> case do
        {:ok, count} -> count
        _ -> 0
      end

    # Get paginated posts
    posts_query =
      Blester.Accounts.Post
      |> Ash.Query.load([:author, :comments])
      |> Ash.Query.sort(inserted_at: :desc)
      |> Ash.Query.limit(limit)
      |> Ash.Query.offset(offset)

    case Ash.read(posts_query) do
      {:ok, posts} ->
        {:ok, {posts, total_count}}
      _ ->
        {:error, :query_failed}
    end
  end

  def update_post(id, attrs) do
    Blester.Accounts.Post
    |> Ash.Query.filter(id: id)
    |> Ash.read_one()
    |> case do
      {:ok, post} ->
        post
        |> Ash.Changeset.for_update(:update, attrs)
        |> Ash.update()
      {:error, _} ->
        {:error, :post_not_found}
    end
  end

  def delete_post(id) do
    Blester.Accounts.Post
    |> Ash.Query.filter(id: id)
    |> Ash.read_one()
    |> case do
      {:ok, post} ->
        Ash.destroy(post)
      {:error, _} ->
        {:error, :post_not_found}
    end
  end

  def create_comment(attrs) do
    Blester.Accounts.Comment
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  def get_comment(id) do
    Blester.Accounts.Comment
    |> Ash.Query.filter(id: id)
    |> Ash.Query.load([:author, :post])
    |> Ash.read_one()
  end

  def get_comments_for_post(post_id) do
    Blester.Accounts.Comment
    |> Ash.Query.filter(post_id: post_id)
    |> Ash.Query.load([:author])
    |> Ash.Query.sort(inserted_at: :asc)
    |> Ash.read()
  end

  def update_comment(id, attrs) do
    Blester.Accounts.Comment
    |> Ash.Query.filter(id: id)
    |> Ash.read_one()
    |> case do
      {:ok, comment} ->
        comment
        |> Ash.Changeset.for_update(:update, attrs)
        |> Ash.update()
      {:error, _} ->
        {:error, :comment_not_found}
    end
  end

  def delete_comment(id) do
    Blester.Accounts.Comment
    |> Ash.Query.filter(id: id)
    |> Ash.read_one()
    |> case do
      {:ok, comment} ->
        Ash.destroy(comment)
      {:error, _} ->
        {:error, :comment_not_found}
    end
  end
end
