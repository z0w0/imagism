import Config

config :imagism,
  port: 8000,
  adapter: "file",
  file_path: "test/images",

config :logger, :console,
  metadata: [:resize, :fit, :w, :h, :crop, :brighten, :blur, :rotate, :flip]
