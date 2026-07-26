# Atlassian OpenAPI references

Use these local schemas when a documented curl command is insufficient or an
endpoint's parameters or response shape must be confirmed. Do not read an
entire schema into model context; query it with `jq` or process it with
`ctx_execute_file`.

## Bundled official schemas

| Product | Local file | Format | Paths | Official source |
| --- | --- | --- | ---: | --- |
| Jira Cloud REST v3 | `openapi/jira-v3.json` | OpenAPI 3.0.1 | 420 | [Atlassian schema][jira] |
| Confluence Cloud REST v2 | `openapi/confluence-v2.json` | OpenAPI 3.0.3 | 151 | [Atlassian schema][confluence] |
| Bitbucket Cloud REST v2 | `openapi/bitbucket-v2.json` | Swagger 2.0 | 193 | [Canonical schema][bitbucket] |

The files were fetched from the official sources on 2026-07-26 without local
modification.

[jira]: https://dac-static.atlassian.com/cloud/jira/platform/swagger-v3.v3.json?_v=1.8516.64
[confluence]: https://dac-static.atlassian.com/cloud/confluence/openapi-v2.v3.json?_v=1.8516.64
[bitbucket]: https://api.bitbucket.org/swagger.json

## Find paths by keyword

Set `schema` to one of the local files and choose a short lowercase query.
Limit results before bringing them into context.

```sh
schema="references/openapi/jira-v3.json"
query="comment"

jq -r --arg query "$query" '
  .paths
  | keys[]
  | select(ascii_downcase | contains($query | ascii_downcase))
' "$schema" | head -50
```

Paths are relative to the skill directory. Resolve them against the directory
containing `SKILL.md` when running commands elsewhere.

## Inspect one path

Use the exact path template from the schema, including braces:

```sh
schema="references/openapi/jira-v3.json"
openapi_path="/rest/api/3/issue/{issueIdOrKey}/comment"

jq --arg path "$openapi_path" '.paths[$path]' "$schema"
```

## Find operations by operation ID or summary

```sh
schema="references/openapi/confluence-v2.json"
query="footer comment"

jq -r --arg query "$query" '
  .paths
  | to_entries[] as $path
  | $path.value
  | to_entries[]
  | select(.key | IN("get", "post", "put", "patch", "delete"))
  | select(
      ((.value.operationId // "") + " " + (.value.summary // ""))
      | test($query; "i")
    )
  | [$path.key, .key, .value.operationId, .value.summary]
  | @tsv
' "$schema" | head -50
```

This skill is read-only. Even if the schema exposes a mutation operation, do
not invoke `post`, `put`, `patch`, or `delete` operations.

## Inspect a response schema

Jira and Confluence use OpenAPI 3 component schemas:

```sh
schema="references/openapi/jira-v3.json"
schema_name="PageOfComments"
jq --arg name "$schema_name" '.components.schemas[$name]' "$schema"
```

Bitbucket uses Swagger 2 definitions:

```sh
schema="references/openapi/bitbucket-v2.json"
schema_name="pullrequest"
jq --arg name "$schema_name" '.definitions[$name]' "$schema"
```

Follow local `$ref` values with a targeted query rather than recursively
expanding the complete schema.

## Refreshing

Schemas change independently of this skill. To refresh, download each official
source to its existing local filename, then verify:

1. The body parses as JSON.
2. The root contains `openapi` or `swagger`.
3. The `paths` object is non-empty.
4. Existing read commands still refer to valid `get` operations.
5. No credentials are needed or sent while downloading public schemas.
