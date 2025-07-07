defmodule Blester.Shop.Product do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "products"
    repo Blester.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :description, :string, allow_nil?: false
    attribute :price, :decimal, allow_nil?: false
    attribute :image_url, :string, allow_nil?: false
    attribute :stock_quantity, :integer, allow_nil?: false, default: 0
    attribute :sku, :string, allow_nil?: false
    attribute :is_active, :boolean, allow_nil?: false, default: true
    attribute :status, :string, allow_nil?: false, default: "active"
    attribute :category_id, :uuid, allow_nil?: false
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  validations do
    validate present([:name, :description, :price, :image_url, :category_id, :sku])
  end

  identities do
    identity :unique_sku, [:sku]
  end

  relationships do
    belongs_to :category, Blester.Shop.Category
    has_many :cart_items, Blester.Shop.CartItem, destination_attribute: :product_id
    has_many :order_items, Blester.Shop.OrderItem, destination_attribute: :product_id
  end

  actions do
    create :create do
      accept [:name, :description, :price, :image_url, :category_id, :stock_quantity, :sku, :is_active, :status]
    end

    update :update do
      accept [:name, :description, :price, :image_url, :category_id, :stock_quantity, :sku, :is_active, :status]
    end

    defaults [:read, :destroy]
  end
end
