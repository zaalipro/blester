defmodule Blester.Accounts.Viewing do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Blester.Accounts

  postgres do
    table "viewings"
    repo Blester.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :scheduled_date, :utc_datetime, allow_nil?: false
    attribute :status, :string, allow_nil?: false, default: "scheduled" # scheduled, completed, cancelled
    attribute :notes, :string
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :user, Blester.Accounts.User do
      allow_nil? false
    end

    belongs_to :property, Blester.Accounts.Property do
      allow_nil? false
    end

    belongs_to :agent, Blester.Accounts.User do
      allow_nil? false
    end
  end

  actions do
    create :create do
      accept [:scheduled_date, :notes, :user_id, :property_id, :agent_id]
    end

    update :update do
      accept [:scheduled_date, :status, :notes]
    end

    defaults [:read, :destroy]
  end
end
