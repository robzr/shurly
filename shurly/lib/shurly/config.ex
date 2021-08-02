# TODO: optimize config loading so we are not converting values every time these functions are called

defmodule Shurly.Config do
  @moduledoc """
  Centralized location for configurable values.
  """

  def hashing_algorithm do
    String.to_atom(System.get_env("SHURLY_HASHING_ALGORITHM") || "sha256")
  end

  def min_slug_length do
    System.get_env("SHURLY_MIN_SLUG_LENGTH") || 5
  end

  # 301 (permanent) - browser caches, faster, but we cannot log usage
  # 302 (temporary) - browser does not cache, slower, but we can log usage
  def redirect_code do
    String.to_integer(System.get_env("SHURLY_REDIRECT_CODE") || "302")
  end

  def redis_url do
    System.get_env("REDIS_URL") || "redis://localhost:6379"
  end

  def shurly_port do
    String.to_integer(System.get_env("SHURLY_PORT") || "8080")
  end
end
