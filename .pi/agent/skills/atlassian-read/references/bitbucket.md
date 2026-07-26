# Bitbucket Cloud read reference

Use this reference for pull requests and review comments. Read `common.md` first
and define `atlassian_get` in the same shell invocation.

## Credentials

```sh
email="${PI_MCP_BITBUCKET_USER_EMAIL:-${PI_MCP_ATLASSIAN_USER_EMAIL:-}}"
token="${PI_MCP_BITBUCKET_API_TOKEN:-${BITBUCKET_API_TOKEN:-}}"

: "${email:?Set PI_MCP_BITBUCKET_USER_EMAIL or PI_MCP_ATLASSIAN_USER_EMAIL}"
: "${token:?Set PI_MCP_BITBUCKET_API_TOKEN}"
```

Use a Bitbucket-scoped token. Do not substitute the Jira or Confluence token.
The fixed read host is `https://api.bitbucket.org`.

## Pull request identifiers

Set these values from a trusted Bitbucket URL or explicit user input:

```sh
workspace="${BITBUCKET_WORKSPACE:?Set BITBUCKET_WORKSPACE}"
repository="${BITBUCKET_REPOSITORY:?Set BITBUCKET_REPOSITORY}"
pull_request_id="${BITBUCKET_PULL_REQUEST_ID:?Set BITBUCKET_PULL_REQUEST_ID}"

printf '%s' "$workspace" | grep -Eq '^[A-Za-z0-9._-]+$' || {
  printf '%s\n' 'Invalid Bitbucket workspace' >&2
  return 2
}
printf '%s' "$repository" | grep -Eq '^[A-Za-z0-9._-]+$' || {
  printf '%s\n' 'Invalid Bitbucket repository slug' >&2
  return 2
}
printf '%s' "$pull_request_id" | grep -Eq '^[0-9]+$' || {
  printf '%s\n' 'Invalid pull request id' >&2
  return 2
}

api_root="https://api.bitbucket.org/2.0/repositories/$workspace/$repository/pullrequests/$pull_request_id"
```

## Fetch pull request metadata

```sh
response_file="$(mktemp -t bitbucket-pr.XXXXXX)"
trap 'rm -f "$response_file"' EXIT HUP INT TERM

atlassian_get "$email" "$token" --output "$response_file" "$api_root"

jq '{
  id,
  title,
  state,
  author: .author.display_name,
  source: {
    repository: .source.repository.full_name,
    branch: .source.branch.name,
    commit: .source.commit.hash
  },
  destination: {
    repository: .destination.repository.full_name,
    branch: .destination.branch.name,
    commit: .destination.commit.hash
  },
  created_on,
  updated_on,
  description,
  link: .links.html.href
}' "$response_file"
```

## Fetch review comments

Fetch a bounded page. Bitbucket returns a `next` URL when more comments exist.
Before fetching it, require its origin to be exactly
`https://api.bitbucket.org`.

```sh
page_length="${PAGE_LENGTH:-20}"
printf '%s' "$page_length" | grep -Eq '^[0-9]+$' || {
  printf '%s\n' 'PAGE_LENGTH must be an integer' >&2
  return 2
}
[ "$page_length" -ge 1 ] && [ "$page_length" -le 100 ] || {
  printf '%s\n' 'PAGE_LENGTH must be between 1 and 100' >&2
  return 2
}

response_file="$(mktemp -t bitbucket-comments.XXXXXX)"
trap 'rm -f "$response_file"' EXIT HUP INT TERM

url="$api_root/comments?pagelen=$page_length"
atlassian_get "$email" "$token" --output "$response_file" "$url"

jq '{
  page,
  pagelen,
  size,
  next,
  comments: [.values[] | {
    id,
    author: .user.display_name,
    created_on,
    updated_on,
    deleted,
    pending,
    parent_id: .parent.id,
    inline: .inline,
    body: .content.raw,
    link: .links.html.href
  }]
}' "$response_file"
```

## Fetch diffstat

Use diffstat rather than the full diff when the user first asks what changed.
It is smaller and usually sufficient for orientation.

```sh
response_file="$(mktemp -t bitbucket-diffstat.XXXXXX)"
trap 'rm -f "$response_file"' EXIT HUP INT TERM

atlassian_get "$email" "$token" --output "$response_file" "$api_root/diffstat?pagelen=100"

jq '{
  size,
  next,
  files: [.values[] | {
    status,
    old_path: .old.path,
    new_path: .new.path,
    lines_added,
    lines_removed
  }]
}' "$response_file"
```
