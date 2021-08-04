defmodule Shurly.Application do
  @moduledoc "OTP Application specification for Shurly URL Shortener"

  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Shurly.Endpoint,
        options: [port: Shurly.Config.shurly_port()]
      ),
      {Redix, {Shurly.Config.redis_url(), [name: :redix]}}
    ]

    opts = [strategy: :one_for_one, name: Shurly.Supervisor]

    Logger.configure(level: :info)

    Supervisor.start_link(children, opts)
  end
end
