defmodule Blester.Shop.Category do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "categories"
    repo Blester.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
  end

  identities do
    identity :unique_name, [:name]
  end

  actions do
    create :create do
      accept [:name]
    end
    update :update do
      accept [:name]
    end
    defaults [:read, :destroy]
  end
end
