defmodule Blester.Repo.Migrations.CreateShopTables do
  use Ecto.Migration

  def change do
    create table(:products, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :description, :text, null: false
      add :price, :decimal, null: false
      add :image_url, :string, null: false
      add :category, :string, null: false
      add :stock_quantity, :integer, null: false, default: 0
      add :sku, :string, null: false
      add :is_active, :boolean, null: false, default: true
      timestamps()
    end
    create unique_index(:products, [:sku])

    create table(:cart_items, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :quantity, :integer, null: false, default: 1
      add :user_id, references(:users, column: :id, type: :uuid, on_delete: :delete_all), null: false
      add :product_id, references(:products, column: :id, type: :uuid, on_delete: :delete_all), null: false
      timestamps()
    end
    create index(:cart_items, [:user_id])
    create index(:cart_items, [:product_id])
    create unique_index(:cart_items, [:user_id, :product_id])

    create table(:orders, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :order_number, :string, null: false
      add :status, :string, null: false, default: "pending"
      add :total_amount, :decimal, null: false
      add :shipping_address, :text, null: false
      add :billing_address, :text, null: false
      add :payment_method, :string, null: false
      add :user_id, references(:users, column: :id, type: :uuid, on_delete: :nilify_all), null: false
      timestamps()
    end
    create unique_index(:orders, [:order_number])
    create index(:orders, [:user_id])

    create table(:order_items, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :quantity, :integer, null: false
      add :unit_price, :decimal, null: false
      add :total_price, :decimal, null: false
      add :order_id, references(:orders, column: :id, type: :uuid, on_delete: :delete_all), null: false
      add :product_id, references(:products, column: :id, type: :uuid, on_delete: :nilify_all), null: false
      timestamps()
    end
    create index(:order_items, [:order_id])
    create index(:order_items, [:product_id])
  end
end
