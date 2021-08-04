# shurly
SHA based URL shortener that allows for offline slug validation with tunable confidence. 

## Overview
Shurly is written in Elixir, using the [Cowboy HTTP server plugin with Poison for JSON parsing][cowboy-poison], and 
[Redix][redix] for communicating with the storage backend. [Redis][redis] is used as a persistent storage backend.

### Hashing and Encoding
In order to balance speed, entropy, and ease of offline validation, SHA-256 was chosen as the hashing algorithm. The 
hashed value is encoded with [URL safe Base64][RFC4648-5], which covers 97% of the [RFC-3986 defined unreserved
character set for URIs][RFC3986-2.3]. This achieves an entropy-dense, RFC-compliant encoding scheme that is easily
verifiable offline in modern operating systems and languages. If a collision is found when a new URL is submitted for
shortening, the length is incremented until an available slug is found.

### Minimum Slug Length
Since the slug is a truncated hash, the liklihood of collisions increases as the slug length decreases. The server
administrator can set the minimum slug length with the `SHURLY_MIN_SLUG_LENGTH` environment variable to accomodate 
the desired slug entropy, which determines confidence in offline validation, and the degree of obscurity for probing
slugs. The probability would be calculated for any two unique URLs validating to the same slug with the formula
`50 / 64^slug_length` (percent), or 1 in `64^slug_length / 2`.

| Number                  | Description                               |
|------------------------:|-------------------------------------------|
|                      32 | mean URLs per collision for 1 digit slug  |
|                   2,048 | mean URLs per collision for 2 digit slug  |
|                 131,072 | mean URLs per collision for 3 digit slug  |
|               8,388,608 | mean URLs per collision for 4 digit slug  |
|              22,075,000 | Seconds in average human lifetime         |
|             536,870,912 | mean URLs per collision for 5 digit slug  |
|           7,846,000,000 | Estimated people in the world             |
|          34,359,738,368 | mean URLs per collision for 6 digit slug  |
|       2,199,023,255,552 | mean URLs per collision for 7 digit slug  |
|      48,000,000,000,000 | Distinct URLs Google "knows about"        |
|     140,737,488,355,328 | mean URLs per collision for 8 digit slug  |
|   9,007,199,254,740,992 | mean URLs per collision for 9 digit slug  |
| 576,460,752,303,423,488 | mean URLs per collision for 10 digit slug |

The chosen default is 5 digits, which should provide a reasonably high level of confidence for small installations.

### Offline Validation
A URL can be validated offline with common UNIX commands.
```
shurly_validate_slug() {
  local slug=${1##*/} # URL will be converted to a slug
  local url=$2

  local encoded=$(echo -n "$url" | sha256sum | cut -f1 -d\  | xxd -r -p | base64 | tr +/ -_)
  echo encoded = $encoded
  [[ "$encoded" != "${encoded#${slug}}" ]]
}

shurly_validate_slug KhtAJ http://example.com/ && echo Matches\! || echo No Match\.
```

## Endpoints
### `GET /v1/url` - get server settings
```
{
  "hashing_algorithm": "sha256",
  "min_slug_length": 5
}
```

### `PUT /v1/url` - create a slug
Data:
```
{
  "url": "http://example.com/"
}
```
Returns:
```
{
  "slug": "KhtAJ"
}
```

### `GET /v1/url/<slug>` - get URL in JSON format without redirection
```
{
  "url": "http://example.com/"
}
```

### `GET /<slug>` - redirects to URL or returns 404 if slug does not exist

## Environment Variables
| Variable                   | Default                | Description                           |
|----------------------------|------------------------|---------------------------------------|
| `SHURLY_HASHING_ALGORITHM` | sha256                 | Hashing algorithm used to build slug  |
| `SHURLY_MIN_SLUG_LENGTH`   | 6                      | Minimum slug length allowed by server |
| `SHURLY_PORT`              | 8080                   | TCP port to listen on                 |
| `SHURLY_REDIRECT_CODE`     | 302                    | HTTP code issued on redirects         |
| `REDIS_URL`                | redis://localhost:6379 | Redis server URL                      |

## TODO
- More exception handling, configurable logging
- Allow users to specify longer `min_slug_length` when requesting slugs
- Add Redis connection pools and hash partitioning for scalability
- PBKDF2 key derivation function for security sensitive applications
- TSDB plugin for Logger for debug and query logs
- optimize, refactor

[rfc3986-2.3]: https://datatracker.ietf.org/doc/html/rfc3986#section-2.3
[rfc4648-5]: https://datatracker.ietf.org/doc/html/rfc4648#section-5
[cowboy-poison]: https://dev.to/jonlunsford/elixir-building-a-small-json-endpoint-with-plug-cowboy-and-poison-1826
[cowboy-howto]: https://www.jungledisk.com/blog/2018/03/19/tutorial-a-simple-http-server-in-elixir/
[cowboy-howto-again]: https://medium.com/@jonlunsford/elixir-building-a-small-json-endpoint-with-plug-cowboy-and-poison-f4bb40c23bf6
[redix]: https://github.com/whatyouhide/redix
[redis]: https://redis.io
