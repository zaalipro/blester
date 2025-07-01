defmodule BlesterWeb.LiveValidations do
  @moduledoc """
  Shared validation functions for LiveView components.
  """

  import Phoenix.LiveView, only: [put_flash: 3]

  @doc """
  Validates user parameters for login/registration.
  """
  def validate_user(user_params) do
    %{}
    |> validate_required_field(user_params, "email", "Email is required")
    |> validate_required_field(user_params, "password", "Password is required")
  end

  @doc """
  Validates registration parameters.
  """
  def validate_registration(user_params) do
    %{}
    |> validate_required_field(user_params, "email", "Email is required")
    |> validate_required_field(user_params, "first_name", "First name is required")
    |> validate_required_field(user_params, "last_name", "Last name is required")
    |> validate_required_field(user_params, "country", "Country is required")
    |> validate_required_field(user_params, "password", "Password is required")
    |> validate_required_field(user_params, "password_confirmation", "Password confirmation is required")
    |> validate_password_match(user_params)
  end

  @doc """
  Validates post parameters.
  """
  def validate_post(post_params) do
    %{}
    |> validate_required_field(post_params, "title", "Title is required")
    |> validate_required_field(post_params, "content", "Content is required")
  end

  @doc """
  Validates comment parameters.
  """
  def validate_comment(comment_params) do
    %{}
    |> validate_required_field(comment_params, "content", "Content is required")
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

  # Private helper functions

  defp validate_required_field(errors, params, field, message) do
    value = params[field]
    if value == "" or is_nil(value) do
      Map.put(errors, String.to_existing_atom(field), message)
    else
      errors
    end
  end

  defp validate_password_match(errors, params) do
    password = params["password"]
    confirmation = params["password_confirmation"]

    if password != confirmation and password != "" and confirmation != "" do
      Map.put(errors, :password_confirmation, "Passwords do not match")
    else
      errors
    end
  end
end
