defmodule Blester.Shop.OrderItem do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "order_items"
    repo Blester.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :quantity, :integer, allow_nil?: false
    attribute :unit_price, :decimal, allow_nil?: false
    attribute :total_price, :decimal, allow_nil?: false
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  validations do
    validate present([:quantity, :unit_price, :total_price])
  end

  relationships do
    belongs_to :order, Blester.Shop.Order, allow_nil?: false
    belongs_to :product, Blester.Shop.Product, allow_nil?: false
  end

  actions do
    create :create do
      accept [:quantity, :unit_price, :total_price, :order_id, :product_id]
    end

    update :update do
      accept [:quantity, :unit_price, :total_price]
    end

    defaults [:read, :destroy]
  end
end
