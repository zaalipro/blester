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
    has_many :posts, Blester.Accounts.Post, destination_attribute: :author_id
    has_many :comments, Blester.Accounts.Comment, destination_attribute: :author_id
    has_many :cart_items, Blester.Accounts.CartItem, destination_attribute: :user_id
    has_many :orders, Blester.Accounts.Order, destination_attribute: :user_id

    # Realtor relationships
    has_many :properties_as_agent, Blester.Accounts.Property, destination_attribute: :agent_id
    has_many :properties_as_owner, Blester.Accounts.Property, destination_attribute: :owner_id
    has_many :favorites, Blester.Accounts.Favorite, destination_attribute: :user_id
    has_many :inquiries, Blester.Accounts.Inquiry, destination_attribute: :user_id
    has_many :viewings, Blester.Accounts.Viewing, destination_attribute: :user_id
    has_many :inquiries_as_agent, Blester.Accounts.Inquiry, destination_attribute: :agent_id
    has_many :viewings_as_agent, Blester.Accounts.Viewing, destination_attribute: :agent_id
  end

  actions do
    create :create do
      accept [:email, :hashed_password, :first_name, :last_name, :country, :role]
    end
    defaults [:read]
  end
end
