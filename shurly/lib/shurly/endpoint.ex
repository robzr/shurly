defmodule Shurly.Endpoint do
  @moduledoc """
  A Plug responsible for logging request info, (de)serializing data, matching routes, and dispatching
  responses.
  """

  require Logger

  use Plug.Router

  plug(Plug.Logger)
  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Poison)
  plug(:dispatch)

  match "/v1/url", via: :get do
    send_resp(
      conn,
      200,
      Poison.encode!(%{
        hashing_algorithm: Shurly.Config.hashing_algorithm(),
        min_slug_length: Shurly.Config.min_slug_length()
      })
    )
  end

  match "/v1/url", via: :put do
    {status, body} =
      if is_map(conn.body_params) && Map.has_key?(conn.body_params, "url") do
        if Shurly.Resolver.is_valid_looking_url?(conn.body_params["url"]) do
          {200, Poison.encode!(%{slug: Shurly.Resolver.register_url(conn.body_params["url"])})}
        else
          {400, Poison.encode!(%{response: "Invalid URL"})}
        end
      else
        {400, Poison.encode!(%{response: "Invalid data"})}
      end

    send_resp(conn, status, body)
  end

  match "/v1/url/:slug", via: :get do
    {status, body} =
      if Shurly.Resolver.is_valid_looking_slug?(slug) do
        if url = Shurly.Resolver.resolve_slug(slug) do
          {200, Poison.encode!(%{url: url})}
        else
          {404, "Invalid slug"}
        end
      else
        {404, "Invalid slug"}
      end

    send_resp(conn, status, body)
  end

  match ":slug", via: :get do
    {conn, status, body} =
      if Shurly.Resolver.is_valid_looking_slug?(slug) do
        if url = Shurly.Resolver.resolve_slug(slug) do
          {put_resp_header(conn, "location", url), Shurly.Config.redirect_code(),
           "Redirecting to #{url}"}
        else
          {conn, 404, "Invalid slug"}
        end
      else
        {conn, 404, "Invalid slug or API endpoint"}
      end

    send_resp(conn, status, body)
  end

  match "", via: :get do
    send_resp(conn, 200, "Shurly you came here on purpose.")
  end

  match _ do
    Logger.debug(IO.inspect(conn.body_params))
    send_resp(conn, 404, "Invalid slug or API endpoint")
  end
end
