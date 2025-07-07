defmodule Blester.Blog.Post do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "posts"
    repo Blester.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :title, :string, allow_nil?: false
    attribute :content, :string, allow_nil?: false
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :author, Blester.Accounts.User do
      allow_nil? false
    end

    has_many :comments, Blester.Blog.Comment
  end

  actions do
    create :create do
      accept [:title, :content, :author_id]
    end

    update :update do
      accept [:title, :content]
    end

    defaults [:read, :destroy]
  end
end
