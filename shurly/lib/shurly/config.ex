defmodule Shurly.Config do
  @moduledoc "Centralized location for configurable values."

  def hashing_algorithm do
    if env_val = System.get_env("SHURLY_HASHING_ALGORITHM") do
      String.to_atom(env_val)
    else
      :sha256
    end
  end

  def min_slug_length do
    if env_val = System.get_env("SHURLY_MIN_SLUG_LENGTH") do
      String.to_integer(env_val)
    else
      5
    end
  end

  # 301 (permanent) - browser caches, faster, but we cannot log usage
  # 302 (temporary) - browser does not cache, slower, but we can log usage
  def redirect_code do
    if env_val = System.get_env("SHURLY_REDIRECT_CODE") do
      String.to_integer(env_val)
    else
      302
    end
  end

  def redis_url do
    System.get_env("REDIS_URL") || "redis://localhost:6379"
  end

  def shurly_port do
    if env_val = System.get_env("SHURLY_PORT") do
      String.to_integer(env_val)
    else
      8080
    end
  end
end
