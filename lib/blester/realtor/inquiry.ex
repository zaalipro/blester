defmodule Blester.Realtor.Inquiry do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "inquiries"
    repo Blester.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :message, :string, allow_nil?: false
    attribute :status, :string, allow_nil?: false, default: "pending"
    attribute :inquiry_type, :string, allow_nil?: false
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
