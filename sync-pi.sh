#!/bin/bash

# Synchronize Pi files that Pi may rewrite atomically and therefore cannot stay
# symlinked safely. Read-only Pi resources remain symlinked by install.sh.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$DOTFILES_DIR/.pi"
LIVE_ROOT="$HOME/.pi"
MUTABLE_FILES=(
    "agent/settings.json"
    "agent/mcp.json"
)

usage() {
    cat <<'EOF'
Usage: ./sync-pi.sh status|pull|push

  status  Compare mutable live Pi files with the dotfiles repository.
  pull    Copy mutable files from ~/.pi into the dotfiles repository.
  push    Back up changed live files, then copy repository versions to ~/.pi.
EOF
}

validate_portable_mcp() {
    local file="$1"
    python3 - "$file" <<'PY'
import json
import re
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as source:
    data = json.load(source)

unsafe = set()
environment_reference = re.compile(r"^\$\{[A-Z][A-Z0-9_]*\}$")
portable_header_value = re.compile(
    r"^(?:(?:Basic|Bearer)\s+)?\$\{[A-Z][A-Z0-9_]*\}$",
    re.IGNORECASE,
)
sensitive_name = re.compile(
    r"token|secret|authorization|api.?key|password|credential",
    re.IGNORECASE,
)
sensitive_flag = re.compile(
    r"^--?(?:api[-_]?key|token|secret|password|authorization|credential)(?:=|$)",
    re.IGNORECASE,
)
sensitive_header = re.compile(
    r"^(?:authorization|proxy-authorization|x-api-key|api-key|x-auth-token)$",
    re.IGNORECASE,
)


def require_environment_reference(value, location):
    if isinstance(value, str):
        if not environment_reference.fullmatch(value):
            unsafe.add(location)
    elif isinstance(value, dict):
        for key, child in value.items():
            require_environment_reference(child, f"{location}.{key}")
    elif isinstance(value, list):
        for index, child in enumerate(value):
            require_environment_reference(child, f"{location}[{index}]")


def inspect_header_argument(value, location):
    header_name, separator, header_value = value.partition(":")
    if separator and sensitive_header.fullmatch(header_name.strip()):
        if not portable_header_value.fullmatch(header_value.strip()):
            unsafe.add(location)


def inspect_arguments(arguments, location):
    for index, argument in enumerate(arguments):
        if not isinstance(argument, str):
            continue
        if argument in ("-H", "--header") and index + 1 < len(arguments):
            header_value = arguments[index + 1]
            if isinstance(header_value, str):
                inspect_header_argument(
                    header_value,
                    f"{location}[{index + 1}]",
                )
            continue
        if argument.startswith("--header="):
            inspect_header_argument(
                argument.split("=", 1)[1],
                f"{location}[{index}]",
            )
            continue
        if not sensitive_flag.match(argument):
            continue
        if "=" in argument:
            require_environment_reference(
                argument.split("=", 1)[1],
                f"{location}[{index}]",
            )
        elif index + 1 < len(arguments):
            require_environment_reference(
                arguments[index + 1],
                f"{location}[{index + 1}]",
            )


def inspect_string(value, location):
    inspect_header_argument(value, location)
    if re.match(r"^(?:Basic|Bearer)\s+", value, re.IGNORECASE):
        if not portable_header_value.fullmatch(value.strip()):
            unsafe.add(location)
    for match in re.finditer(
        r"(?:[?&])(?:api[-_]?key|token|secret|password)=([^&]+)",
        value,
        re.IGNORECASE,
    ):
        if not environment_reference.fullmatch(match.group(1)):
            unsafe.add(location)


def walk(value, location=""):
    if isinstance(value, dict):
        for key, child in value.items():
            child_location = f"{location}.{key}" if location else key
            if location != "mcpServers" and sensitive_name.search(key):
                require_environment_reference(child, child_location)
            if key == "args" and isinstance(child, list):
                inspect_arguments(child, child_location)
            if key == "env" and isinstance(child, dict):
                for env_name, env_value in child.items():
                    if sensitive_name.search(env_name):
                        require_environment_reference(
                            env_value,
                            f"{child_location}.{env_name}",
                        )
            walk(child, child_location)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            walk(child, f"{location}[{index}]")
    elif isinstance(value, str):
        inspect_string(value, location)


walk(data)
if unsafe:
    print("Refusing to sync literal sensitive MCP values:", file=sys.stderr)
    for location in unsafe:
        print(f"  {location}", file=sys.stderr)
    raise SystemExit(1)
PY
}

copy_atomically() {
    local source_file="$1"
    local target_file="$2"
    local temporary_file

    mkdir -p "$(dirname "$target_file")"
    temporary_file="$(mktemp "${target_file}.tmp.XXXXXX")"
    cp "$source_file" "$temporary_file"
    chmod "$(stat -f '%Lp' "$source_file")" "$temporary_file"
    mv "$temporary_file" "$target_file"
}

backup_live_file() {
    local relative_path="$1"
    local source_file="$LIVE_ROOT/$relative_path"
    local timestamp="$2"
    local backup_file="$LIVE_ROOT/backups/$timestamp/$relative_path"

    [ -e "$source_file" ] || return 0
    mkdir -p "$(dirname "$backup_file")"
    chmod 700 "$LIVE_ROOT/backups" "$LIVE_ROOT/backups/$timestamp"
    if [ -e "$backup_file" ]; then
        printf 'Refusing to overwrite Pi backup: %s\n' "$backup_file" >&2
        exit 1
    fi
    mv "$source_file" "$backup_file"
    chmod 600 "$backup_file"
    printf 'Backed up %s to %s\n' "$source_file" "$backup_file"
}

assert_owned_live_symlink() {
    local live_file="$1"
    local repo_file="$2"

    if [ -L "$live_file" ] && [ "$(readlink "$live_file")" != "$repo_file" ]; then
        printf 'Refusing to replace unmanaged Pi symlink: %s\n' "$live_file" >&2
        exit 1
    fi
}

status_files() {
    local relative_path repo_file live_file
    for relative_path in "${MUTABLE_FILES[@]}"; do
        repo_file="$REPO_ROOT/$relative_path"
        live_file="$LIVE_ROOT/$relative_path"
        if [ ! -e "$repo_file" ]; then
            printf '%s: missing from repository\n' "$relative_path"
        elif [ ! -e "$live_file" ]; then
            printf '%s: missing from live configuration\n' "$relative_path"
        elif cmp -s "$repo_file" "$live_file"; then
            printf '%s: synchronized\n' "$relative_path"
        else
            printf '%s: different\n' "$relative_path"
        fi
    done
}

pull_files() {
    local relative_path repo_file live_file
    for relative_path in "${MUTABLE_FILES[@]}"; do
        repo_file="$REPO_ROOT/$relative_path"
        live_file="$LIVE_ROOT/$relative_path"
        assert_owned_live_symlink "$live_file" "$repo_file"
        [ -f "$live_file" ] || {
            printf 'Missing live Pi file: %s\n' "$live_file" >&2
            exit 1
        }
        if [ "$relative_path" = "agent/mcp.json" ]; then
            validate_portable_mcp "$live_file"
        fi
        if [ -e "$repo_file" ] && cmp -s "$live_file" "$repo_file"; then
            printf '%s: already synchronized\n' "$relative_path"
            continue
        fi
        copy_atomically "$live_file" "$repo_file"
        printf 'Pulled %s into the repository\n' "$relative_path"
    done
}

push_files() {
    local timestamp relative_path repo_file live_file
    timestamp="$(date +%Y%m%d%H%M%S)"
    for relative_path in "${MUTABLE_FILES[@]}"; do
        repo_file="$REPO_ROOT/$relative_path"
        live_file="$LIVE_ROOT/$relative_path"
        assert_owned_live_symlink "$live_file" "$repo_file"
        [ -f "$repo_file" ] || {
            printf 'Missing repository Pi file: %s\n' "$repo_file" >&2
            exit 1
        }
        if [ "$relative_path" = "agent/mcp.json" ]; then
            validate_portable_mcp "$repo_file"
        fi
        if [ -e "$live_file" ] && cmp -s "$repo_file" "$live_file"; then
            printf '%s: already synchronized\n' "$relative_path"
            continue
        fi
        if [ -L "$live_file" ]; then
            rm "$live_file"
        elif [ -e "$live_file" ]; then
            backup_live_file "$relative_path" "$timestamp"
        fi
        copy_atomically "$repo_file" "$live_file"
        printf 'Pushed %s into the live configuration\n' "$relative_path"
    done
}

case "${1:-}" in
    status) status_files ;;
    pull) pull_files ;;
    push) push_files ;;
    *) usage; exit 2 ;;
esac
