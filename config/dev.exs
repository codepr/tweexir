import Config

config :tweexir,
  bearer_token: System.get_env("TWITTER_AUTH_TOKEN")
