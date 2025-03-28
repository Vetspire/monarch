import Config

config :monarch,
  environment: config_env()

import_config "#{config_env()}.exs"
