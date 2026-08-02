#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_file() {
    [ -f "$1" ] || fail "expected file: $1"
}

assert_symlink() {
    [ -L "$1" ] || fail "expected symlink: $1"
}

assert_same() {
    cmp -s "$1" "$2" || fail "expected identical files: $1 and $2"
}

run_install_fragment_test() {
    local home="$TEST_ROOT/install-home"
    local fragment="$TEST_ROOT/install-pi-fragment.sh"

    mkdir -p "$home/.pi/agent"
    printf 'old settings\n' > "$home/.pi/agent/settings.json"
    printf 'legacy backup\n' > \
        "$home/.pi/agent/example.txt.backup.20200102030405"

    awk '
        /# 12\. Setup Pi configuration/ { capture = 1 }
        /# 13\. Setup Oh My Pi configuration/ { capture = 0 }
        capture
    ' "$REPO_ROOT/install.sh" > "$fragment"

    HOME="$home" DOTFILES_DIR="$REPO_ROOT" bash -c '
        set -e
        info() { :; }
        success() { :; }
        error() { printf "%s\n" "$1" >&2; }
        source "$1"
    ' _ "$fragment"

    assert_file "$home/.pi/agent/settings.json"
    [ ! -L "$home/.pi/agent/settings.json" ] || \
        fail "settings.json must remain a regular mutable copy"
    assert_same \
        "$home/.pi/agent/settings.json" \
        "$REPO_ROOT/.pi/agent/settings.json"
    assert_symlink "$home/.pi/agent/AGENTS.md"
    assert_file \
        "$home/.pi/backups/20200102030405/agent/example.txt"

    local backup_count
    backup_count="$(find "$home/.pi/backups" -type f | wc -l | tr -d ' ')"
    [ "$backup_count" = "2" ] || \
        fail "expected two organized install backups, got $backup_count"
}

prepare_sync_fixture() {
    local fixture="$1"
    mkdir -p "$fixture/repo/.pi/agent" "$fixture/home/.pi/agent"
    cp "$REPO_ROOT/sync-pi.sh" "$fixture/repo/sync-pi.sh"
    cp "$REPO_ROOT/.pi/agent/settings.json" \
        "$fixture/repo/.pi/agent/settings.json"
    cp "$REPO_ROOT/.pi/agent/mcp.json" \
        "$fixture/repo/.pi/agent/mcp.json"
    cp "$REPO_ROOT/validate-portable-mcp.py" \
        "$fixture/repo/validate-portable-mcp.py"
    cp "$REPO_ROOT/validate-personal-config.py" \
        "$fixture/repo/validate-personal-config.py"
    cp "$fixture/repo/.pi/agent/settings.json" \
        "$fixture/home/.pi/agent/settings.json"
    cp "$fixture/repo/.pi/agent/mcp.json" \
        "$fixture/home/.pi/agent/mcp.json"
}

run_sync_round_trip_test() {
    local fixture="$TEST_ROOT/sync-round-trip"
    prepare_sync_fixture "$fixture"

    printf '\n' >> "$fixture/home/.pi/agent/settings.json"
    HOME="$fixture/home" "$fixture/repo/sync-pi.sh" pull >/dev/null
    assert_same \
        "$fixture/home/.pi/agent/settings.json" \
        "$fixture/repo/.pi/agent/settings.json"

    printf '\n' >> "$fixture/repo/.pi/agent/settings.json"
    HOME="$fixture/home" "$fixture/repo/sync-pi.sh" push >/dev/null
    assert_same \
        "$fixture/home/.pi/agent/settings.json" \
        "$fixture/repo/.pi/agent/settings.json"

    local backup_count
    backup_count="$(find "$fixture/home/.pi/backups" -type f | wc -l | tr -d ' ')"
    [ "$backup_count" = "1" ] || \
        fail "expected one push backup, got $backup_count"
    [ "$(stat -f '%Lp' "$fixture/home/.pi/backups")" = "700" ] || \
        fail "backup root must use mode 700"
}

write_unsafe_mcp() {
    local path="$1"
    local representation="$2"
    python3 - "$path" "$representation" <<'PY'
import json
import sys

path, representation = sys.argv[1:]
with open(path, encoding="utf-8") as source:
    data = json.load(source)
server = {"url": "https://example.invalid"}
if representation == "header":
    server["headers"] = {"Authorization": "literal-test-secret"}
elif representation == "argument":
    server["command"] = "example"
    server["args"] = ["--api-key", "literal-test-secret"]
elif representation == "header-argument":
    server["command"] = "example"
    server["args"] = ["--header", "Authorization: Bearer literal-test-secret"]
elif representation == "header-equals":
    server["command"] = "example"
    server["args"] = ["--header=X-API-Key: literal-test-secret"]
elif representation == "header-mixed":
    server["command"] = "example"
    server["args"] = [
        "--header",
        "Authorization: Bearer ${TOKEN}literal-test-secret",
    ]
elif representation == "environment":
    server["command"] = "example"
    server["env"] = {"API_TOKEN": "literal-test-secret"}
data["mcpServers"]["unsafe-test"] = server
with open(path, "w", encoding="utf-8") as target:
    json.dump(data, target)
PY
}

run_secret_validation_tests() {
    local representation fixture
    for representation in \
        header argument header-argument header-equals header-mixed environment; do
        fixture="$TEST_ROOT/secret-$representation"
        prepare_sync_fixture "$fixture"
        write_unsafe_mcp \
            "$fixture/home/.pi/agent/mcp.json" \
            "$representation"
        if HOME="$fixture/home" \
            "$fixture/repo/sync-pi.sh" pull >/dev/null 2>&1; then
            fail "unsafe MCP $representation representation was accepted"
        fi
    done
}

run_portable_header_test() {
    local fixture="$TEST_ROOT/portable-header"
    prepare_sync_fixture "$fixture"
    python3 - "$fixture/home/.pi/agent/mcp.json" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as source:
    data = json.load(source)
data["mcpServers"]["portable-token-service"] = {
    "command": "example",
    "args": ["--header", "Authorization: Bearer ${TOKEN}"],
    "headers": {"Accept": "application/json"},
}
with open(path, "w", encoding="utf-8") as target:
    json.dump(data, target)
PY
    HOME="$fixture/home" "$fixture/repo/sync-pi.sh" pull >/dev/null
}

run_unmanaged_symlink_test() {
    local fixture="$TEST_ROOT/unmanaged-symlink"
    local unmanaged="$fixture/unmanaged-settings.json"
    prepare_sync_fixture "$fixture"
    cp "$fixture/home/.pi/agent/settings.json" "$unmanaged"
    rm "$fixture/home/.pi/agent/settings.json"
    ln -s "$unmanaged" "$fixture/home/.pi/agent/settings.json"

    if HOME="$fixture/home" \
        "$fixture/repo/sync-pi.sh" pull >/dev/null 2>&1; then
        fail "unmanaged live symlink was accepted during pull"
    fi

    printf '\n' >> "$fixture/repo/.pi/agent/settings.json"
    if HOME="$fixture/home" \
        "$fixture/repo/sync-pi.sh" push >/dev/null 2>&1; then
        fail "unmanaged live symlink was accepted during push"
    fi
    assert_symlink "$fixture/home/.pi/agent/settings.json"
}


bash -n "$REPO_ROOT/install.sh"
bash -n "$REPO_ROOT/sync-pi.sh"
run_install_fragment_test
run_sync_round_trip_test
run_secret_validation_tests
run_portable_header_test
run_unmanaged_symlink_test
printf 'Pi configuration tests passed\n'
