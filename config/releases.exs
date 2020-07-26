import Config

config :imagism,
  adapter: System.get_env("IMAGISM_ADAPTER"),
  file_path: System.get_env("IMAGISM_FILE_PATH")
