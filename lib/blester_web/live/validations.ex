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
  Validates registration parameters.
  """
  def validate_registration(user_params) do
    errors = %{}
    errors = if user_params["email"] == "" or is_nil(user_params["email"]), do: Map.put(errors, :email, "Email is required"), else: errors
    errors = if user_params["first_name"] == "" or is_nil(user_params["first_name"]), do: Map.put(errors, :first_name, "First name is required"), else: errors
    errors = if user_params["last_name"] == "" or is_nil(user_params["last_name"]), do: Map.put(errors, :last_name, "Last name is required"), else: errors
    errors = if user_params["country"] == "" or is_nil(user_params["country"]), do: Map.put(errors, :country, "Country is required"), else: errors
    errors = if user_params["password"] == "" or is_nil(user_params["password"]), do: Map.put(errors, :password, "Password is required"), else: errors
    errors = if user_params["password_confirmation"] == "" or is_nil(user_params["password_confirmation"]), do: Map.put(errors, :password_confirmation, "Password confirmation is required"), else: errors

    # Check if passwords match
    if user_params["password"] != user_params["password_confirmation"] and user_params["password"] != "" and user_params["password_confirmation"] != "" do
      Map.put(errors, :password_confirmation, "Passwords do not match")
    else
      errors
    end
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
  def format_errors(errors) when is_list(errors) do
    errors
    |> Enum.map(fn {field, {message, _}} -> {field, message} end)
    |> Enum.into(%{})
  end

  def format_errors(%Ash.Error.Invalid{} = ash_error) do
    ash_error.errors
    |> Enum.map(fn
      %Ash.Error.Changes.Required{field: field} ->
        {field, "is required"}
      %Ash.Error.Changes.InvalidAttribute{field: field, message: message} ->
        {field, message}
      %Ash.Error.Invalid.NoSuchInput{input: input} ->
        {input, "is not a valid field"}
      %Ash.Error.Changes.InvalidChanges{message: message} ->
        {:base, message}
      _ ->
        {:base, "Invalid data"}
    end)
    |> Enum.into(%{})
  end

  def format_errors(_) do
    %{:base => "An unexpected error occurred"}
  end

  @doc """
  Adds auto-dismiss timer for flash messages.
  """
  def add_flash_timer(socket, message_type, message) do
    Process.send_after(self(), :clear_flash, 3000)
    put_flash(socket, message_type, message)
  end
end
