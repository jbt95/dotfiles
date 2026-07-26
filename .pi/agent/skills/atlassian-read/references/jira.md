# Jira Cloud read reference

Use this reference for Jira issues and issue comments. Read `common.md` first
and define its helpers in the same shell invocation.

## Credentials and site

```sh
email="${PI_MCP_JIRA_USER_EMAIL:-${PI_MCP_ATLASSIAN_USER_EMAIL:-}}"
token="${PI_MCP_JIRA_API_TOKEN:-${JIRA_API_TOKEN:-}}"
base_url="${PI_MCP_JIRA_BASE_URL:-${JIRA_BASE_URL:-}}"

: "${email:?Set PI_MCP_JIRA_USER_EMAIL or PI_MCP_ATLASSIAN_USER_EMAIL}"
: "${token:?Set PI_MCP_JIRA_API_TOKEN}"
: "${base_url:?Set PI_MCP_JIRA_BASE_URL, for example https://example.atlassian.net}"

base_url="$(validate_atlassian_site_url "$base_url")" || return 2
```

Use a Jira-scoped token. Do not substitute the Bitbucket or Confluence token.
Typical read access requires Jira issue and user read scopes.

## Fetch an issue

Set `ISSUE_KEY` from the user's request, then validate it before constructing
the URL.

```sh
issue_key="${ISSUE_KEY:?Set ISSUE_KEY, for example ABC-123}"
printf '%s' "$issue_key" | grep -Eq '^[A-Za-z][A-Za-z0-9_]+-[0-9]+$' || {
  printf '%s\n' 'Invalid Jira issue key' >&2
  return 2
}

response_file="$(mktemp -t jira-issue.XXXXXX)"
trap 'rm -f "$response_file"' EXIT HUP INT TERM

url="$base_url/rest/api/3/issue/$issue_key?fields=summary,description,status,issuetype,priority,assignee,reporter,labels,components,created,updated,parent,subtasks"
atlassian_get "$email" "$token" --output "$response_file" "$url"

jq '{
  key,
  summary: .fields.summary,
  type: .fields.issuetype.name,
  status: .fields.status.name,
  priority: .fields.priority.name,
  assignee: .fields.assignee.displayName,
  reporter: .fields.reporter.displayName,
  labels: .fields.labels,
  components: [.fields.components[]?.name],
  created: .fields.created,
  updated: .fields.updated,
  parent: .fields.parent.key,
  subtasks: [.fields.subtasks[]? | {key, summary: .fields.summary}],
  description: .fields.description
}' "$response_file"
```

Jira descriptions use Atlassian Document Format. Preserve the JSON structure
when exact formatting matters; recursively collect `text` fields only when a
plain-text summary is sufficient.

## Fetch issue comments

Fetch a bounded first page. Increase `maxResults` up to 100 only when needed.
Use `startAt` for subsequent pages when `total` exceeds the returned count.

```sh
issue_key="${ISSUE_KEY:?Set ISSUE_KEY}"
start_at="${START_AT:-0}"
max_results="${MAX_RESULTS:-20}"

case "$start_at:$max_results" in
  *[!0-9:]*|'')
    printf '%s\n' 'Pagination values must be integers' >&2
    return 2
    ;;
esac
[ "$max_results" -ge 1 ] && [ "$max_results" -le 100 ] || {
  printf '%s\n' 'MAX_RESULTS must be between 1 and 100' >&2
  return 2
}

response_file="$(mktemp -t jira-comments.XXXXXX)"
trap 'rm -f "$response_file"' EXIT HUP INT TERM

query="startAt=$start_at&maxResults=$max_results&orderBy=created"
url="$base_url/rest/api/3/issue/$issue_key/comment?$query"
atlassian_get "$email" "$token" --output "$response_file" "$url"

jq '{
  startAt,
  maxResults,
  total,
  comments: [.comments[] | {
    id,
    author: .author.displayName,
    created,
    updated,
    body
  }]
}' "$response_file"
```
