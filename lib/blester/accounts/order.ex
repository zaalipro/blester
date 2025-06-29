defmodule Blester.Accounts.Order do
  use Ash.Resource,
    domain: Blester.Accounts,
    data_layer: AshPostgres.DataLayer

  # Table name
  postgres do
    table "orders"
    repo Blester.Repo
  end

  # Attributes
  attributes do
    uuid_primary_key :id
    attribute :order_number, :string, allow_nil?: false
    attribute :status, :string, allow_nil?: false, default: "pending"
    attribute :total_amount, :decimal, allow_nil?: false
    attribute :shipping_address, :string, allow_nil?: false
    attribute :billing_address, :string, allow_nil?: false
    attribute :payment_method, :string, allow_nil?: false
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  # Validations
  validations do
    validate present([:order_number, :total_amount, :shipping_address, :billing_address, :payment_method])
  end

  identities do
    identity :unique_order_number, [:order_number]
  end

  relationships do
    belongs_to :user, Blester.Accounts.User, allow_nil?: false
    has_many :order_items, Blester.Accounts.OrderItem, destination_attribute: :order_id
  end

  actions do
    create :create do
      accept [:order_number, :status, :total_amount, :shipping_address, :billing_address, :payment_method, :user_id]
    end

    update :update do
      accept [:status, :total_amount, :shipping_address, :billing_address, :payment_method]
    end

    defaults [:read, :destroy]
  end
end
