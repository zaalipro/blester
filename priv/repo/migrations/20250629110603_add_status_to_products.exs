defmodule Blester.Repo.Migrations.AddStatusToProducts do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :status, :string, null: false, default: "active"
    end
  end
end
