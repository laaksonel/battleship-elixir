import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :battleship_interface, BattleshipInterfaceWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "n7I2eU3CmiowDP56nNC0QvvzSMK/w8T6XyxMsEFVIArziIv7ztJyY/YmjLONwdq0",
  server: false

# In test we don't send emails.
config :battleship_interface, BattleshipInterface.Mailer,
  adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
