defmodule Blester.Accounts.Comment do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Blester.Accounts

  postgres do
    table "comments"
    repo Blester.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :content, :string, allow_nil?: false
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :author, Blester.Accounts.User do
      allow_nil? false
    end

    belongs_to :post, Blester.Accounts.Post do
      allow_nil? false
    end
  end

  actions do
    create :create do
      accept [:content, :author_id, :post_id]
    end

    defaults [:read, :update, :destroy]
  end
end
