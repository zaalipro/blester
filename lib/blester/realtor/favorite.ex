defmodule Blester.Realtor.Favorite do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "favorites"
    repo Blester.Repo
  end

  attributes do
    uuid_primary_key :id
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :user, Blester.Accounts.User do
      allow_nil? false
    end
    belongs_to :property, Blester.Realtor.Property do
      allow_nil? false
    end
  end
end
