defmodule Alfred.Entities.Plugin do
  use Ecto.Schema

  schema "plugin" do
    field :key, :string
    field :definition, :string
  end

  defmodule Repo do
    use Ecto.Repo, otp_app: :alfred
  end
end
