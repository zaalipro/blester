defmodule Blester.Blog.Comment do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

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

    belongs_to :post, Blester.Blog.Post do
      allow_nil? false
    end
  end

  actions do
    create :create do
      accept [:content, :author_id, :post_id]
    end

    update :update do
      accept [:content]
    end

    defaults [:read, :destroy]
  end
end
