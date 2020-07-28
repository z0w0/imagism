import Config

config :imagism,
  port: System.get_env("PORT") || 8000,
  adapter: System.get_env("IMAGISM_ADAPTER") || "file",
  file_path: System.get_env("IMAGISM_FILE_PATH") || "test/images",
  s3_bucket: System.get_env("IMAGISM_S3_BUCKET"),
  s3_region: System.get_env("IMAGISM_S3_REGION")

config :logger, :console,
  metadata: [:resize, :fit, :w, :h, :crop, :brighten, :blur, :rotate, :flip]
