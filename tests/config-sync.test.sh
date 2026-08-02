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

assert_regular_file() {
    assert_file "$1"
    [ ! -L "$1" ] || fail "expected regular file: $1"
}

assert_same() {
    cmp -s "$1" "$2" || fail "expected identical files: $1 and $2"
}

run_omp_install_fragment() {
    local home="$1"
    local fragment="$TEST_ROOT/omp-install-fragment.sh"

    {
        awk '
            /^copy_managed_file\(\)/ { capture = 1 }
            /^# \.zshrc/ { capture = 0 }
            capture
        ' "$REPO_ROOT/install.sh"
        awk '
            /# 13\. Setup Oh My Pi configuration/ { capture = 1 }
            /# 14\. Install VS Code Extensions/ { capture = 0 }
            capture
        ' "$REPO_ROOT/install.sh"
    } > "$fragment"

    HOME="$home" DOTFILES_DIR="$REPO_ROOT" bash -c '
        set -e
        info() { :; }
        success() { :; }
        error() { printf "%s\n" "$1" >&2; }
        source "$1"
    ' _ "$fragment"
}

run_omp_install_test() {
    local home="$TEST_ROOT/install-home"
    mkdir -p "$home"

    run_omp_install_fragment "$home"
    for relative_path in agent/config.yml agent/RULES.md agent/mcp.json; do
        assert_regular_file "$home/.omp/$relative_path"
        assert_same "$REPO_ROOT/.omp/$relative_path" "$home/.omp/$relative_path"
    done
    [ ! -e "$home/.omp/agent.db" ] || fail "OMP database was created"
    [ ! -e "$home/.omp/sessions" ] || fail "OMP sessions were created"
    [ ! -e "$home/.omp/run" ] || fail "OMP runtime directory was created"

    printf '\nchanged live preference\n' >> "$home/.omp/agent/config.yml"
    run_omp_install_fragment "$home"
    assert_same "$REPO_ROOT/.omp/agent/config.yml" "$home/.omp/agent/config.yml"
    find "$home/.omp/agent" -type f -name 'config.yml.backup.*' -print -quit | grep -q . || \
        fail "changed OMP file was not backed up by installer"
}

prepare_omp_fixture() {
    local fixture="$1"
    mkdir -p "$fixture/repo/.omp/agent" "$fixture/home/.omp/agent"
    cp "$REPO_ROOT/sync-omp.sh" "$fixture/repo/sync-omp.sh"
    cp "$REPO_ROOT/validate-portable-mcp.py" \
        "$fixture/repo/validate-portable-mcp.py"
    cp "$REPO_ROOT/validate-personal-config.py" \
        "$fixture/repo/validate-personal-config.py"
    for relative_path in agent/config.yml agent/RULES.md agent/mcp.json; do
        cp "$REPO_ROOT/.omp/$relative_path" \
            "$fixture/repo/.omp/$relative_path"
        cp "$fixture/repo/.omp/$relative_path" \
            "$fixture/home/.omp/$relative_path"
    done
}

run_omp_round_trip_test() {
    local fixture="$TEST_ROOT/round-trip"
    local backup_root
    prepare_omp_fixture "$fixture"

    printf '\nchanged live rule\n' >> "$fixture/home/.omp/agent/RULES.md"
    HOME="$fixture/home" "$fixture/repo/sync-omp.sh" pull >/dev/null
    assert_same \
        "$fixture/home/.omp/agent/RULES.md" \
        "$fixture/repo/.omp/agent/RULES.md"

    printf '\nchanged repository preference\n' >> \
        "$fixture/repo/.omp/agent/config.yml"
    HOME="$fixture/home" "$fixture/repo/sync-omp.sh" push >/dev/null
    assert_same \
        "$fixture/home/.omp/agent/config.yml" \
        "$fixture/repo/.omp/agent/config.yml"

    [ "$(find "$fixture/home/.omp/backups" -type f | wc -l | tr -d ' ')" = "1" ] || \
        fail "expected one OMP backup file"
    [ "$(stat -f '%Lp' "$fixture/home/.omp/backups")" = "700" ] || \
        fail "OMP backup root must use mode 700"
    backup_root="$(find "$fixture/home/.omp/backups" -mindepth 1 -maxdepth 1 -type d -print -quit)"
    [ -n "$backup_root" ] || fail "missing OMP timestamp backup directory"
    [ "$(stat -f '%Lp' "$backup_root")" = "700" ] || \
        fail "OMP timestamp backup directory must use mode 700"
    [ "$(stat -f '%Lp' "$backup_root/agent")" = "700" ] || \
        fail "OMP backup agent directory must use mode 700"
}

run_unmanaged_symlink_test() {
    local fixture="$TEST_ROOT/unmanaged-symlink"
    local unmanaged="$fixture/unmanaged-config.yml"
    prepare_omp_fixture "$fixture"
    cp "$fixture/home/.omp/agent/config.yml" "$unmanaged"
    rm "$fixture/home/.omp/agent/config.yml"
    ln -s "$unmanaged" "$fixture/home/.omp/agent/config.yml"

    if HOME="$fixture/home" \
        "$fixture/repo/sync-omp.sh" pull >/dev/null 2>&1; then
        fail "unmanaged OMP symlink was accepted during pull"
    fi
    if HOME="$fixture/home" \
        "$fixture/repo/sync-omp.sh" push >/dev/null 2>&1; then
        fail "unmanaged OMP symlink was accepted during push"
    fi
    [ -L "$fixture/home/.omp/agent/config.yml" ] || \
        fail "unmanaged OMP symlink was replaced"
}

write_mcp_case() {
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
elif representation == "environment":
    server["command"] = "example"
    server["env"] = {"API_TOKEN": "literal-test-secret"}
elif representation == "query":
    server["url"] += "?token=literal-test-secret"
elif representation == "direct":
    server["apiKey"] = "literal-test-secret"
elif representation == "mixed":
    server["headers"] = {
        "Authorization": "Bearer ${TOKEN}literal-test-secret",
    }
else:
    raise SystemExit("unknown test case")
data["mcpServers"]["unsafe-test"] = server
with open(path, "w", encoding="utf-8") as target:
    json.dump(data, target)
PY
}

run_mcp_credential_rejection_tests() {
    local representation fixture before
    for representation in header argument environment query direct mixed; do
        fixture="$TEST_ROOT/unsafe-$representation"
        prepare_omp_fixture "$fixture"
        before="$fixture/repo/.omp/agent/mcp.json.before"
        cp "$fixture/repo/.omp/agent/mcp.json" "$before"
        write_mcp_case "$fixture/home/.omp/agent/mcp.json" "$representation"
        if HOME="$fixture/home" \
            "$fixture/repo/sync-omp.sh" pull >/dev/null 2>&1; then
            fail "unsafe MCP $representation representation was accepted"
        fi
        assert_same "$before" "$fixture/repo/.omp/agent/mcp.json"
    done
}

run_portable_reference_test() {
    local fixture="$TEST_ROOT/portable-reference"
    prepare_omp_fixture "$fixture"
    python3 - "$fixture/home/.omp/agent/mcp.json" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as source:
    data = json.load(source)
data["mcpServers"]["portable-test"] = {
    "url": "https://example.invalid/mcp?token=${CONTEXT7_API_KEY}",
    "command": "example",
    "args": ["--header", "Authorization: Bearer ${CONTEXT7_API_KEY}"],
    "env": {"API_TOKEN": "${CONTEXT7_API_KEY}"},
    "apiKey": "${CONTEXT7_API_KEY}",
}
with open(path, "w", encoding="utf-8") as target:
    json.dump(data, target)
PY
    HOME="$fixture/home" "$fixture/repo/sync-omp.sh" pull >/dev/null
    assert_same \
        "$fixture/home/.omp/agent/mcp.json" \
        "$fixture/repo/.omp/agent/mcp.json"
}

run_marker_rejection_tests() {
    local marker fixture before
    for marker in org service email prefix ca; do
        fixture="$TEST_ROOT/marker-$marker"
        prepare_omp_fixture "$fixture"
        before="$fixture/repo/.omp/agent/mcp.json.before"
        cp "$fixture/repo/.omp/agent/mcp.json" "$before"
        python3 - "$fixture/home/.omp/agent/mcp.json" "$marker" <<'PY'
import json
import sys

path, marker_name = sys.argv[1:]
marker_values = {
    "org": "can" + "da",
    "service": "can" + "da-services",
    "email": "j.bermejo@" + "can" + "da.com",
    "prefix": "ILC" + "_",
    "ca": "CORPORATE" + "_CA_FILE",
}
with open(path, encoding="utf-8") as source:
    data = json.load(source)
data["mcpServers"]["marker-test"] = {
    "url": "https://example.invalid",
    "description": marker_values[marker_name],
}
with open(path, "w", encoding="utf-8") as target:
    json.dump(data, target)
PY
        if HOME="$fixture/home" \
            "$fixture/repo/sync-omp.sh" pull >/dev/null 2>&1; then
            fail "personal marker $marker was accepted"
        fi
        assert_same "$before" "$fixture/repo/.omp/agent/mcp.json"
    done
}

bash -n "$REPO_ROOT/install.sh"
bash -n "$REPO_ROOT/sync-omp.sh"
run_omp_install_test
run_omp_round_trip_test
run_unmanaged_symlink_test
run_mcp_credential_rejection_tests
run_portable_reference_test
run_marker_rejection_tests
printf 'OMP configuration tests passed\n'
