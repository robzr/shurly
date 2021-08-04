ARG image=elixir:1.12
FROM ${image}
ARG hashing_algorithm=sha256
ARG min_slug_length=5
ARG port=8080
ARG redirect_code=302
ARG redis_url=redis://localhost:6379
ENV REDIS_URL=${redis_url}
ENV SHURLY_MIN_SLUG_LENGTH=${min_slug_length}
ENV SHURLY_HASHING_ALGORITHM=${hashing_algorithm}
ENV SHURLY_PORT=${port}
ENV SHURLY_REDIRECT_CODE=${redirect_code}
WORKDIR /app
COPY shurly/ /app
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get --force && \
    mix release
CMD ["_build/dev/rel/shurly/bin/shurly", "start"]
