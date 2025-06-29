defmodule BlesterWeb.LiveValidations do
  @moduledoc """
  Shared validation functions for LiveView components.
  """

  import Phoenix.LiveView, only: [put_flash: 3, clear_flash: 2]

  @doc """
  Validates user parameters for login/registration.
  """
  def validate_user(user_params) do
    errors = %{}
    errors = if user_params["email"] == "" or is_nil(user_params["email"]), do: Map.put(errors, :email, "Email is required"), else: errors
    errors = if user_params["password"] == "" or is_nil(user_params["password"]), do: Map.put(errors, :password, "Password is required"), else: errors
    errors
  end

  @doc """
  Validates post parameters.
  """
  def validate_post(post_params) do
    errors = %{}
    errors = if post_params["title"] == "" or is_nil(post_params["title"]), do: Map.put(errors, :title, "Title is required"), else: errors
    errors = if post_params["content"] == "" or is_nil(post_params["content"]), do: Map.put(errors, :content, "Content is required"), else: errors
    errors
  end

  @doc """
  Validates comment parameters.
  """
  def validate_comment(comment_params) do
    errors = %{}
    errors = if comment_params["content"] == "" or is_nil(comment_params["content"]), do: Map.put(errors, :content, "Content is required"), else: errors
    errors
  end

  @doc """
  Formats Ash changeset errors to a simple map.
  """
  def format_errors(errors) do
    errors
    |> Enum.map(fn {field, {message, _}} -> {field, message} end)
    |> Enum.into(%{})
  end

  @doc """
  Adds auto-dismiss timer for flash messages.
  """
  def add_flash_timer(socket, message_type, message) do
    Process.send_after(self(), :clear_flash, 3000)
    put_flash(socket, message_type, message)
  end
end
