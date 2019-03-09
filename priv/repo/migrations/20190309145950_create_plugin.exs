defmodule Workflow.Repo.Migrations.CreatePlugin do
  use Ecto.Migration

  def change do
    create table(:plugin) do
      add :key, :string, null: false
      add :definition, :text, null: false
    end
  end
end
