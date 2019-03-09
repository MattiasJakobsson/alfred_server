defmodule Workflow do
  use Ecto.Schema

  schema "workflow" do
    field :triggers, :string
    field :definition, :string
  end
end
