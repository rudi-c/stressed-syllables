# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :stressed_syllables,
  ecto_repos: []
  # ecto_repos: [StressedSyllables.Repo]

# Configures the endpoint
config :stressed_syllables, StressedSyllablesWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "lbQdWb7UaOkVLTZlPpC/HSuhs3LhC0OcUPYIuy/UHyzE4w6Y+HIn9ji2f1C9Ev3R",
  render_errors: [view: StressedSyllablesWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: StressedSyllables.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
