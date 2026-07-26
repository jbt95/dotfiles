# Common curl rules

Read this reference before a product reference.

## Safe authenticated GET helper

Define this helper once in the current shell invocation. It passes Basic Auth
credentials to curl through standard input rather than placing the expanded
credential in curl's process arguments.

```sh
atlassian_get() {
  if [ "$#" -lt 3 ]; then
    printf '%s\n' 'usage: atlassian_get EMAIL TOKEN CURL_ARGUMENTS...' >&2
    return 2
  fi

  local email="$1"
  local token="$2"
  shift 2

  if [ -z "$email" ] || [ -z "$token" ]; then
    printf '%s\n' 'Atlassian email and product token are required' >&2
    return 2
  fi

  printf 'user = "%s:%s"\n' "$email" "$token" |
    curl --disable --config - \
      --proto '=https' \
      --fail-with-body \
      --silent \
      --show-error \
      --connect-timeout 10 \
      --max-time 30 \
      --header 'Accept: application/json' \
      "$@"
}

validate_atlassian_site_url() {
  python3 - "$1" <<'PY'
import sys
from urllib.parse import urlsplit

value = sys.argv[1]
try:
    parsed = urlsplit(value)
    port = parsed.port
except ValueError:
    raise SystemExit("Invalid Atlassian site URL")

hostname = (parsed.hostname or "").lower()
valid = (
    parsed.scheme == "https"
    and hostname.endswith(".atlassian.net")
    and parsed.username is None
    and parsed.password is None
    and port is None
    and parsed.path in ("", "/")
    and not parsed.query
    and not parsed.fragment
)
if not valid:
    raise SystemExit(
        "Atlassian site URL must be an HTTPS atlassian.net origin"
    )
print(f"https://{hostname}")
PY
}
```

Do not add `--location`: redirects can forward credentials to an unintended
host. Do not add verbose or trace flags.

## Response handling

Prefer a bounded `jq` projection:

```sh
response_file="$(mktemp -t atlassian-read.XXXXXX)"
trap 'rm -f "$response_file"' EXIT HUP INT TERM

atlassian_get "$email" "$token" --output "$response_file" "$url"
jq '{id, key, title, state, status}' "$response_file"
```

Adapt the projection to the product response. Do not print a large raw response
when only a few fields are relevant.

For paginated responses:

1. Fetch one page using the product's documented maximum page size.
2. Inspect `total`/`size`, `startAt`, or `next`.
3. Fetch another page only if the user needs data beyond the first page.
4. Validate every `next` URL against the documented product host before using
   it. Never follow a server-provided URL blindly.

## Common failures

- `401`: wrong product token, expired token, or wrong email.
- `403`: token lacks the required product scope or the account lacks access.
- `404`: resource absent or deliberately hidden by permissions.
- `429`: rate limited; report the failure and retry only when the user asks or
  the response supplies a short `Retry-After` value.
