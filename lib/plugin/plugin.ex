defmodule Plugin do
  use Ecto.Schema

  schema "plugin" do
    field :key, :string
    field :definition, :string
  end
end
