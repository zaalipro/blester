defmodule Blester.Shop.CartItem do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "cart_items"
    repo Blester.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :quantity, :integer, allow_nil?: false, default: 1
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  validations do
    validate present([:quantity])
  end

  relationships do
    belongs_to :user, Blester.Accounts.User, allow_nil?: false
    belongs_to :product, Blester.Shop.Product, allow_nil?: false
  end

  actions do
    create :create do
      accept [:quantity, :user_id, :product_id]
    end

    update :update do
      accept [:quantity]
    end

    defaults [:read, :destroy]
  end
end
