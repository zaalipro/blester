defmodule Blester.Accounts.Property do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Blester.Accounts

  postgres do
    table "properties"
    repo Blester.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :title, :string, allow_nil?: false
    attribute :description, :string, allow_nil?: false
    attribute :price, :decimal, allow_nil?: false
    attribute :bedrooms, :integer, allow_nil?: false
    attribute :bathrooms, :integer, allow_nil?: false
    attribute :square_feet, :integer, allow_nil?: false
    attribute :address, :string, allow_nil?: false
    attribute :city, :string, allow_nil?: false
    attribute :state, :string, allow_nil?: false
    attribute :zip_code, :string, allow_nil?: false
    attribute :property_type, :string, allow_nil?: false # house, condo, townhouse, etc.
    attribute :status, :string, allow_nil?: false, default: "active" # active, sold, pending, inactive
    attribute :listing_date, :utc_datetime, allow_nil?: false
    attribute :images, {:array, :string}, default: []
    attribute :virtual_tour_url, :string
    attribute :latitude, :decimal
    attribute :longitude, :decimal
    attribute :amenities, {:array, :string}, default: []
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :agent, Blester.Accounts.User do
      allow_nil? false
    end

    belongs_to :owner, Blester.Accounts.User do
      allow_nil? false
    end

    has_many :favorites, Blester.Accounts.Favorite
    has_many :inquiries, Blester.Accounts.Inquiry
    has_many :viewings, Blester.Accounts.Viewing
  end

  actions do
    create :create do
      accept [:title, :description, :price, :bedrooms, :bathrooms, :square_feet,
              :address, :city, :state, :zip_code, :property_type, :listing_date,
              :images, :virtual_tour_url, :latitude, :longitude, :amenities, :agent_id, :owner_id, :status]
    end

    update :update do
      accept [:title, :description, :price, :bedrooms, :bathrooms, :square_feet,
              :address, :city, :state, :zip_code, :property_type, :status,
              :images, :virtual_tour_url, :latitude, :longitude, :amenities]
    end

    defaults [:read, :destroy]
  end
end
