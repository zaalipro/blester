defmodule Blester.Realtor.Viewing do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "viewings"
    repo Blester.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :scheduled_date, :utc_datetime, allow_nil?: false
    attribute :status, :string, allow_nil?: false, default: "scheduled"
    attribute :notes, :string
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
    belongs_to :agent, Blester.Accounts.User do
      allow_nil? false
    end
  end
end
