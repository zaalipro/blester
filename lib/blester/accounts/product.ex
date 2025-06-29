defmodule Blester.Accounts.Product do
  use Ash.Resource,
    domain: Blester.Accounts,
    data_layer: AshPostgres.DataLayer

  # Table name
  postgres do
    table "products"
    repo Blester.Repo
  end

  # Attributes
  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :description, :string, allow_nil?: false
    attribute :price, :decimal, allow_nil?: false
    attribute :image_url, :string, allow_nil?: false
    attribute :category, :string, allow_nil?: false
    attribute :stock_quantity, :integer, allow_nil?: false, default: 0
    attribute :sku, :string, allow_nil?: false
    attribute :is_active, :boolean, allow_nil?: false, default: true
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  # Validations
  validations do
    validate present([:name, :description, :price, :image_url, :category, :sku])
  end

  identities do
    identity :unique_sku, [:sku]
  end

  relationships do
    has_many :cart_items, Blester.Accounts.CartItem, destination_attribute: :product_id
    has_many :order_items, Blester.Accounts.OrderItem, destination_attribute: :product_id
  end

  actions do
    create :create do
      accept [:name, :description, :price, :image_url, :category, :stock_quantity, :sku, :is_active]
    end

    update :update do
      accept [:name, :description, :price, :image_url, :category, :stock_quantity, :sku, :is_active]
    end

    defaults [:read, :destroy]
  end
end
