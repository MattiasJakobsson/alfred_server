defmodule Alfred.Entities.Workflow do
  use Ecto.Schema

  schema "workflow" do
    field :triggers, :string
    field :definition, :string
  end

  defmodule Repo do
    use Ecto.Repo, otp_app: :alfred
  end
end
