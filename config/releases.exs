import Config

config :imagism,
  port: System.get_env("PORT"),
  adapter: System.get_env("IMAGISM_ADAPTER"),
  file_path: System.get_env("IMAGISM_FILE_PATH"),
  s3_bucket: System.get_env("IMAGISM_S3_BUCKET"),
  s3_region: System.get_env("IMAGISM_S3_REGION")
