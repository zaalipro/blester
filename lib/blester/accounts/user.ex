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
    attribute :hashed_password, :string, allow_nil?: false
    attribute :first_name, :string, allow_nil?: false
    attribute :last_name, :string, allow_nil?: false
    attribute :country, :string, allow_nil?: false
    attribute :role, :string, allow_nil?: false, default: "user"
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
    # Removed cross-domain relationships to Blog, Shop, and Property resources
  end

  actions do
    create :create do
      accept [:email, :hashed_password, :first_name, :last_name, :country, :role]
    end
    defaults [:read]
  end
end
