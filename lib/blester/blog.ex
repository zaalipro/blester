defmodule Blester.Blog do
  use Ash.Domain

  resources do
    resource Blester.Blog.Post
    resource Blester.Blog.Comment
  end

  @moduledoc """
  Unified context for blog-related operations (posts and comments).
  """
  alias Blester.Blog.Post
  alias Blester.Blog.Comment
  require Ash.Query

  # --- Post Functions ---
  @spec create_post(map()) :: {:ok, Post.t()} | {:error, term()}
  def create_post(attrs) do
    attrs = for {key, val} <- attrs, into: %{} do
      case key do
        key when is_binary(key) -> {String.to_existing_atom(key), val}
        key when is_atom(key) -> {key, val}
      end
    end
    Post
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  @spec get_post(String.t()) :: {:ok, Post.t()} | {:error, term()}
  def get_post(id) do
    Post
    |> Ash.Query.filter(id: id)
    |> Ash.Query.load([:author, comments: [:author]])
    |> Ash.read_one(domain: __MODULE__)
  end

  @spec list_posts() :: {:ok, [Post.t()]} | {:error, term()}
  def list_posts do
    Post
    |> Ash.Query.load([:author, comments: [:author]])
    |> Ash.Query.sort(inserted_at: :desc)
    |> Ash.read()
  end

  @spec list_posts_paginated(integer(), integer(), String.t()) :: {:ok, {[Post.t()], integer()}} | {:error, term()}
  def list_posts_paginated(limit, offset, search \\ "") do
    total_count_query = Post
    |> Ash.Query.load([:author, comments: [:author]])
    total_count_query = if search != "" do
      total_count_query |> Ash.Query.filter(title: search)
    else
      total_count_query
    end
    total_count = total_count_query |> Ash.count(domain: __MODULE__) |> case do
      {:ok, count} -> count
      _ -> 0
    end
    posts_query = Post
    |> Ash.Query.load([:author, comments: [:author]])
    |> Ash.Query.sort(inserted_at: :desc)
    |> Ash.Query.limit(limit)
    |> Ash.Query.offset(offset)
    posts_query = if search != "" do
      posts_query |> Ash.Query.filter(title: search)
    else
      posts_query
    end
    case Ash.read(posts_query, domain: __MODULE__) do
      {:ok, posts} -> {:ok, {posts, total_count}}
      _ -> {:error, :query_failed}
    end
  end

  # --- Comment Functions ---
  # Add comment-related functions here as needed

  @spec delete_comment(String.t()) :: {:ok, Comment.t()} | {:error, term()}
  def delete_comment(comment_id) do
    Comment
    |> Ash.Query.filter(id: comment_id)
    |> Ash.read_one()
    |> case do
      {:ok, comment} ->
        comment
        |> Ash.Changeset.for_destroy(:destroy)
        |> Ash.destroy()
      error ->
        error
    end
  end
  @spec create_comment(map()) :: {:ok, Comment.t()} | {:error, term()}
  def create_comment(attrs) do
    attrs = for {key, val} <- attrs, into: %{} do
      case key do
        key when is_binary(key) -> {String.to_existing_atom(key), val}
        key when is_atom(key) -> {key, val}
      end
    end
    Comment
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  @spec update_comment(String.t(), map()) :: {:ok, Comment.t()} | {:error, term()}
  def update_comment(comment_id, attrs) do
    Comment
    |> Ash.Query.filter(id: comment_id)
    |> Ash.read_one()
    |> case do
      {:ok, comment} ->
        comment
        |> Ash.Changeset.for_update(:update, attrs)
        |> Ash.update()
      error ->
        error
    end
  end

  @spec update_post(String.t(), map()) :: {:ok, Post.t()} | {:error, term()}
  def update_post(post_id, attrs) do
    Post
    |> Ash.Query.filter(id: post_id)
    |> Ash.read_one(domain: __MODULE__)
    |> case do
      {:ok, post} ->
        post
        |> Ash.Changeset.for_update(:update, attrs)
        |> Ash.update(domain: __MODULE__)
      error ->
        error
    end
  end

  @spec delete_post(String.t()) :: :ok | {:error, term()}
  def delete_post(post_id) do
    Post
    |> Ash.Query.filter(id: post_id)
    |> Ash.read_one()
    |> case do
      {:ok, post} ->
        case post |> Ash.Changeset.for_destroy(:destroy) |> Ash.destroy() do
          {:ok, _} -> :ok
          {:error, reason} -> {:error, reason}
        end
      error ->
        error
    end
  end

  @spec get_comment(String.t()) :: {:ok, Comment.t()} | {:error, term()}
  def get_comment(comment_id) do
    Comment
    |> Ash.Query.filter(id: comment_id)
    |> Ash.read_one()
  end

  @spec get_comments_for_post(String.t()) :: {:ok, [Comment.t()]} | {:error, term()}
  def get_comments_for_post(post_id) do
    Comment
    |> Ash.Query.filter(post_id: post_id)
    |> Ash.Query.sort(inserted_at: :asc)
    |> Ash.read()
  end
end
