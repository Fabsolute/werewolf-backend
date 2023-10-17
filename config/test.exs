import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :werewolf, WerewolfWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "MQ0DDXm2IuNiKOydJUuF54FJpHT3ohYFErWrlXiz9+RKJbJVkwViFZQDMQrXI/wN",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
