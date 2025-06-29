defmodule Blester.Accounts.Inquiry do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Blester.Accounts

  postgres do
    table "inquiries"
    repo Blester.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :message, :string, allow_nil?: false
    attribute :status, :string, allow_nil?: false, default: "pending" # pending, responded, closed
    attribute :inquiry_type, :string, allow_nil?: false # viewing, offer, question
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
      accept [:message, :inquiry_type, :user_id, :property_id, :agent_id]
    end

    update :update do
      accept [:status]
    end

    defaults [:read, :destroy]
  end
end
