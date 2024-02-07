defmodule OllamaLive.Repo do
  use Ecto.Repo,
    otp_app: :ollama_live,
    adapter: Ecto.Adapters.Postgres
end
