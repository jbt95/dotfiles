#!/bin/bash

# Synchronize the small, portable Oh My Pi configuration allowlist. Runtime
# databases, sessions, logs, caches, binaries, and credentials stay live-only.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$DOTFILES_DIR/.omp"
LIVE_ROOT="$HOME/.omp"
MUTABLE_FILES=(
    "agent/config.yml"
    "agent/RULES.md"
    "agent/mcp.json"
)

usage() {
    cat <<'EOF'
Usage: ./sync-omp.sh status|pull|push

  status  Compare allowlisted live OMP files with the repository.
  pull    Copy validated allowlisted files from ~/.omp into the repository.
  push    Back up changed live files, then copy repository files to ~/.omp.
EOF
}

validate_portable_mcp() {
    python3 "$DOTFILES_DIR/validate-portable-mcp.py" "$1"
}

validate_personal_config() {
    python3 "$DOTFILES_DIR/validate-personal-config.py" "$1"
}

copy_atomically() {
    local source_file="$1"
    local target_file="$2"
    local target_parent temporary_file

    target_parent="$(dirname "$target_file")"
    if [ -L "$target_parent" ]; then
        printf 'Refusing to follow unmanaged directory symlink: %s\n' "$target_parent" >&2
        exit 1
    fi
    mkdir -p "$target_parent"
    temporary_file="$(mktemp "${target_file}.tmp.XXXXXX")"
    cp "$source_file" "$temporary_file"
    chmod "$(stat -f '%Lp' "$source_file")" "$temporary_file"
    mv "$temporary_file" "$target_file"
}

backup_live_file() {
    local relative_path="$1"
    local source_file="$LIVE_ROOT/$relative_path"
    local timestamp="$2"
    local backup_root="$LIVE_ROOT/backups/$timestamp"
    local backup_file="$backup_root/$relative_path"
    local source_mode

    [ -e "$source_file" ] || return 0
    source_mode="$(stat -f '%Lp' "$source_file")"
    mkdir -p "$(dirname "$backup_file")"
    chmod 700 "$LIVE_ROOT/backups" "$backup_root" "$backup_root/agent"
    if [ -e "$backup_file" ]; then
        printf 'Refusing to overwrite OMP backup: %s\n' "$backup_file" >&2
        exit 1
    fi
    mv "$source_file" "$backup_file"
    chmod "$source_mode" "$backup_file"
    printf 'Backed up %s to %s\n' "$source_file" "$backup_file"
}

assert_owned_live_symlink() {
    local live_file="$1"
    local repo_file="$2"

    if [ -L "$live_file" ] && [ "$(readlink "$live_file")" != "$repo_file" ]; then
        printf 'Refusing to replace unmanaged OMP symlink: %s\n' "$live_file" >&2
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

validate_live_sources() {
    local relative_path repo_file live_file
    for relative_path in "${MUTABLE_FILES[@]}"; do
        repo_file="$REPO_ROOT/$relative_path"
        live_file="$LIVE_ROOT/$relative_path"
        assert_owned_live_symlink "$live_file" "$repo_file"
        [ -f "$live_file" ] || {
            printf 'Missing live OMP file: %s\n' "$live_file" >&2
            exit 1
        }
        validate_personal_config "$live_file"
        if [ "$relative_path" = "agent/mcp.json" ]; then
            validate_portable_mcp "$live_file"
        fi
    done
}

pull_files() {
    local relative_path repo_file live_file

    validate_live_sources
    for relative_path in "${MUTABLE_FILES[@]}"; do
        repo_file="$REPO_ROOT/$relative_path"
        live_file="$LIVE_ROOT/$relative_path"
        if [ -e "$repo_file" ] && cmp -s "$live_file" "$repo_file"; then
            printf '%s: already synchronized\n' "$relative_path"
            continue
        fi
        copy_atomically "$live_file" "$repo_file"
        printf 'Pulled %s into the repository\n' "$relative_path"
    done
}

validate_repository_sources() {
    local relative_path repo_file live_file
    for relative_path in "${MUTABLE_FILES[@]}"; do
        repo_file="$REPO_ROOT/$relative_path"
        live_file="$LIVE_ROOT/$relative_path"
        assert_owned_live_symlink "$live_file" "$repo_file"
        [ -f "$repo_file" ] || {
            printf 'Missing repository OMP file: %s\n' "$repo_file" >&2
            exit 1
        }
        validate_personal_config "$repo_file"
        if [ "$relative_path" = "agent/mcp.json" ]; then
            validate_portable_mcp "$repo_file"
        fi
    done
}

push_files() {
    local timestamp relative_path repo_file live_file

    validate_repository_sources
    timestamp="$(date +%Y%m%d%H%M%S)"
    for relative_path in "${MUTABLE_FILES[@]}"; do
        repo_file="$REPO_ROOT/$relative_path"
        live_file="$LIVE_ROOT/$relative_path"
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
