defmodule Blester.Repo.Migrations.CreateRealtorTables do
  use Ecto.Migration

  def change do
    create table(:properties, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :string, null: false
      add :description, :text, null: false
      add :price, :decimal, null: false
      add :bedrooms, :integer, null: false
      add :bathrooms, :integer, null: false
      add :square_feet, :integer, null: false
      add :address, :string, null: false
      add :city, :string, null: false
      add :state, :string, null: false
      add :zip_code, :string, null: false
      add :property_type, :string, null: false
      add :status, :string, null: false, default: "active"
      add :listing_date, :utc_datetime, null: false
      add :images, {:array, :string}, default: []
      add :virtual_tour_url, :string
      add :latitude, :decimal
      add :longitude, :decimal
      add :amenities, {:array, :string}, default: []
      add :agent_id, references(:users, column: :id, type: :uuid, on_delete: :nothing), null: false
      add :owner_id, references(:users, column: :id, type: :uuid, on_delete: :nothing), null: false
      timestamps()
    end
    create index(:properties, [:agent_id])
    create index(:properties, [:owner_id])
    create index(:properties, [:city])
    create index(:properties, [:state])
    create index(:properties, [:status])

    create table(:favorites, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_id, references(:users, column: :id, type: :uuid, on_delete: :delete_all), null: false
      add :property_id, references(:properties, column: :id, type: :uuid, on_delete: :delete_all), null: false
      timestamps()
    end
    create index(:favorites, [:user_id])
    create index(:favorites, [:property_id])
    create unique_index(:favorites, [:user_id, :property_id])

    create table(:inquiries, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :message, :text, null: false
      add :status, :string, null: false, default: "pending"
      add :inquiry_type, :string, null: false
      add :user_id, references(:users, column: :id, type: :uuid, on_delete: :nothing), null: false
      add :property_id, references(:properties, column: :id, type: :uuid, on_delete: :nothing), null: false
      add :agent_id, references(:users, column: :id, type: :uuid, on_delete: :nothing), null: false
      timestamps()
    end
    create index(:inquiries, [:user_id])
    create index(:inquiries, [:property_id])
    create index(:inquiries, [:agent_id])

    create table(:viewings, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :scheduled_date, :utc_datetime, null: false
      add :status, :string, null: false, default: "scheduled"
      add :notes, :text
      add :user_id, references(:users, column: :id, type: :uuid, on_delete: :nothing), null: false
      add :property_id, references(:properties, column: :id, type: :uuid, on_delete: :nothing), null: false
      add :agent_id, references(:users, column: :id, type: :uuid, on_delete: :nothing), null: false
      timestamps()
    end
    create index(:viewings, [:user_id])
    create index(:viewings, [:property_id])
    create index(:viewings, [:agent_id])
  end
end
