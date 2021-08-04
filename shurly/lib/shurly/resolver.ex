# TODO: handle Redis exceptions gracefully

defmodule Shurly.Resolver do
  @moduledoc "Functions for registering and resolving slugs."

  require Logger

  def is_valid_looking_slug?(slug) do
    String.match?(slug, ~r/^[a-z0-9_-]+$/i) and
      String.length(slug) >= Shurly.Config.min_slug_length() and
      String.length(slug) <= Shurly.Config.max_slug_length()
  end

  # Must be http(s), RFC-1123 / RFC-952 compliant host/domain names or IPs, and include a trailing `/` to meet coding
  # exercise instructions
  def is_valid_looking_url?(url) do
    String.match?(url, ~r/^https?:\/\/[a-z0-9\.-]+\//i)
  end

  def register_url(url) do
    register_url(
      url,
      String.slice(
        hash_encode_url(url),
        0,
        Shurly.Config.max_slug_length()
      )
    )
  end

  def resolve_slug(slug) do
    {:ok, url} = Redix.command(:redix, ["get", slug])
    url
  end

  defp hash_encode_url(url) do
    String.replace(
      :crypto.hash(Shurly.Config.hashing_algorithm(), url) |> Base.encode64(),
      ["+", "/", "="],
      fn char -> %{"+" => "-", "/" => "_", "=" => ""}[char] end
    )
  end

  defp register_url(url, slug) do
    if String.length(slug) >= Shurly.Config.min_slug_length() do
      if registered_slug = register_url(url, String.slice(slug, 0, String.length(slug) - 1)) do
        registered_slug
      else
        existing_url = resolve_slug(slug)

        if url == existing_url do
          slug
        else
          if !existing_url do
            Logger.debug("register_url() - calling Redis to set #{slug} = #{url}")
            {:ok, _} = Redix.command(:redix, ["set", slug, url])
            slug
          end
        end
      end
    end
  end
end
