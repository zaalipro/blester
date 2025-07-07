defmodule Blester.Accounts do
  use Ash.Domain

  @moduledoc """
  The Accounts context is now focused solely on user-related logic.
  Shop, Property, and Blog logic have been moved to their respective contexts:
    - Blester.Shop
    - Blester.Realtor
    - Blester.Blog
  """

  resources do
    resource Blester.Accounts.User
  end

  alias Blester.Accounts.User
  require Ash.Query

  @spec get_user_by_email(String.t()) :: {:ok, User.t()} | {:error, term()}
  def get_user_by_email(email) do
    User
    |> Ash.Query.filter(email: email)
    |> Ash.read_one()
  end

  @spec get_user(String.t()) :: {:ok, User.t()} | {:error, term()}
  def get_user(id) do
    User
    |> Ash.Query.filter(id: id)
    |> Ash.read_one()
  end

  @spec create_user(map()) :: {:ok, User.t()} | {:error, term()}
  def create_user(attrs) do
    attrs = for {key, val} <- attrs, into: %{} do
      case key do
        key when is_binary(key) -> {String.to_existing_atom(key), val}
        key when is_atom(key) -> {key, val}
      end
    end
    attrs = Map.put(attrs, :hashed_password, Bcrypt.hash_pwd_salt(attrs.password))
    attrs = Map.delete(attrs, :password)
    User
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  @spec authenticate_user(String.t(), String.t()) :: {:ok, User.t()} | {:error, :invalid_credentials}
  def authenticate_user(email, password) do
    case get_user_by_email(email) do
      {:ok, user} ->
        if Bcrypt.verify_pass(password, user.hashed_password) do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end
      {:error, _} ->
        {:error, :invalid_credentials}
    end
  end

  @spec count_users() :: {:ok, integer()} | {:error, term()}
  def count_users do
    User
    |> Ash.count()
  end
end
