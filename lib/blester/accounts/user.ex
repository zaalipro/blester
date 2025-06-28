defmodule Blester.Accounts.User do
  use Ash.Resource,
    domain: Blester.Accounts,
    data_layer: AshPostgres.DataLayer

  # Table name
  postgres do
    table "users"
    repo Blester.Repo
  end

  # Attributes
  attributes do
    uuid_primary_key :id
    attribute :email, :ci_string, allow_nil?: false
    attribute :hashed_password, :string, allow_nil?: false, sensitive?: true
    attribute :first_name, :string, allow_nil?: false
    attribute :last_name, :string, allow_nil?: false
    attribute :country, :string, allow_nil?: false
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  # Validations
  validations do
    validate present([:email, :hashed_password, :first_name, :last_name, :country])
  end

  identities do
    identity :unique_email, [:email]
  end

  relationships do
    has_many :posts, Blester.Accounts.Post, destination_attribute: :author_id

    has_many :comments, Blester.Accounts.Comment, destination_attribute: :author_id
  end

  actions do
    create :create do
      accept [:email, :hashed_password, :first_name, :last_name, :country]
    end

    defaults [:read]
  end

  # Manual authentication implementation
  def authenticate(email, password) do
    case Blester.Accounts.get_user_by_email(email) do
      {:ok, nil} ->
        {:error, :user_not_found}
      {:ok, user} ->
        if Bcrypt.verify_pass(password, user.hashed_password) do
          {:ok, user}
        else
          {:error, :invalid_password}
        end
      {:error, _} ->
        {:error, :user_not_found}
    end
  end

  def hash_password(password) do
    Bcrypt.hash_pwd_salt(password)
  end
end
