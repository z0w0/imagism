defmodule Imagism.Cache do
  use Nebulex.Cache,
    otp_app: :imagism,
    adapter: Nebulex.Adapters.Local
end
