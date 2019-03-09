defmodule Workflow.Repo.Migrations.CreateWorkflow do
  use Ecto.Migration

  def change do
    create table(:workflow) do
      add :triggers, :text, null: false
      add :definition, :text, null: false
    end
  end
end
