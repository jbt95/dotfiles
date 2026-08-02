#!/bin/bash

# Synchronize OpenCode configuration between the dotfiles repository and
# ~/.config/opencode.
#
# - Mutable files (AGENTS.md, dcp.jsonc, opencode.json) are copied like Pi's
#   mutable settings.
# - Resource directories (agents/, command/, skills/) are managed as symlinks
#   per tracked file, matching install.sh. New files present only in live are
#   discovered and pulled into the repository.
# - Runtime directories (node_modules/, context-mode/, secrets/, auth stores)
#   are intentionally ignored.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$DOTFILES_DIR/opencode"
LIVE_ROOT="$HOME/.config/opencode"
MUTABLE_FILES=(
    "AGENTS.md"
    "dcp.jsonc"
    "opencode.json:template"
)
RESOURCE_DIRS=(
    "agents"
    "command"
    "skills"
)

usage() {
    cat <<'EOF'
Usage: ./sync-opencode.sh status|pull|push

  status  Compare live OpenCode files and tracked resources with the repository.
  pull    Copy live changes into the repository and re-establish managed links.
  push    Back up changed live files, then copy repository versions into place.
EOF
}

repo_path_for() {
    local mapping="$1"
    local relative_path="${mapping%%:*}"
    local suffix="${mapping#*:}"
    if [ "$suffix" = "template" ]; then
        printf '%s/%s.template\n' "$REPO_ROOT" "$relative_path"
    else
        printf '%s/%s\n' "$REPO_ROOT" "$relative_path"
    fi
}

live_path_for() {
    local mapping="$1"
    local relative_path="${mapping%%:*}"
    printf '%s/%s\n' "$LIVE_ROOT" "$relative_path"
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
    chmod 700 "$LIVE_ROOT/backups" "$backup_root"
    if [ -e "$backup_file" ]; then
        printf 'Refusing to overwrite OpenCode backup: %s\n' "$backup_file" >&2
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
        printf 'Refusing to replace unmanaged OpenCode symlink: %s\n' "$live_file" >&2
        exit 1
    fi
}

assert_safe_parent() {
    local target_file="$1"
    local target_parent

    target_parent="$(dirname "$target_file")"
    if [ -L "$target_parent" ]; then
        printf 'Refusing to follow unmanaged directory symlink: %s\n' "$target_parent" >&2
        exit 1
    fi
}

status_files() {
    local mapping relative_path repo_file live_file
    for mapping in "${MUTABLE_FILES[@]}"; do
        relative_path="${mapping%%:*}"
        repo_file="$(repo_path_for "$mapping")"
        live_file="$(live_path_for "$mapping")"
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

tracked_resource_files() {
    local directory
    for directory in "${RESOURCE_DIRS[@]}"; do
        [ -d "$REPO_ROOT/$directory" ] || continue
        find "$REPO_ROOT/$directory" -type f -print0 2>/dev/null
    done
}

status_resources() {
    local repo_file relative_path live_file
    tracked_resource_files | while IFS= read -r -d '' repo_file; do
        relative_path="${repo_file#"$REPO_ROOT/"}"
        live_file="$LIVE_ROOT/$relative_path"
        if [ ! -e "$live_file" ]; then
            printf '%s: missing from live configuration\n' "$relative_path"
        elif [ -L "$live_file" ] && [ "$(readlink "$live_file")" = "$repo_file" ]; then
            printf '%s: synchronized\n' "$relative_path"
        elif [ -L "$live_file" ]; then
            printf '%s: unmanaged symlink\n' "$relative_path"
        elif cmp -s "$repo_file" "$live_file"; then
            printf '%s: synchronized\n' "$relative_path"
        else
            printf '%s: different\n' "$relative_path"
        fi
    done
}

status_all() {
    status_files
    status_resources
}

validate_live_sources() {
    local mapping relative_path repo_file live_file
    for mapping in "${MUTABLE_FILES[@]}"; do
        relative_path="${mapping%%:*}"
        repo_file="$(repo_path_for "$mapping")"
        live_file="$(live_path_for "$mapping")"
        assert_owned_live_symlink "$live_file" "$repo_file"
        [ -f "$live_file" ] || {
            printf 'Missing live OpenCode file: %s\n' "$live_file" >&2
            exit 1
        }
        validate_personal_config "$live_file"
    done

    local resource_file
    tracked_resource_files | while IFS= read -r -d '' resource_file; do
        relative_path="${resource_file#"$REPO_ROOT/"}"
        live_file="$LIVE_ROOT/$relative_path"
        assert_owned_live_symlink "$live_file" "$resource_file"
        [ -f "$live_file" ] || {
            printf 'Missing live OpenCode file: %s\n' "$live_file" >&2
            exit 1
        }
        validate_personal_config "$live_file"
    done
}

validate_new_live_resource() {
    local live_file="$1"
    local relative_path="${live_file#"$LIVE_ROOT/"}"

    assert_owned_live_symlink "$live_file" "$REPO_ROOT/$relative_path"
    validate_personal_config "$live_file"
}

pull_files() {
    local mapping relative_path repo_file live_file

    validate_live_sources
    for mapping in "${MUTABLE_FILES[@]}"; do
        relative_path="${mapping%%:*}"
        repo_file="$(repo_path_for "$mapping")"
        live_file="$(live_path_for "$mapping")"
        if [ -e "$repo_file" ] && cmp -s "$live_file" "$repo_file"; then
            printf '%s: already synchronized\n' "$relative_path"
            continue
        fi
        copy_atomically "$live_file" "$repo_file"
        printf 'Pulled %s into the repository\n' "$relative_path"
    done
}

pull_resources() {
    local repo_file relative_path live_file
    tracked_resource_files | while IFS= read -r -d '' repo_file; do
        relative_path="${repo_file#"$REPO_ROOT/"}"
        live_file="$LIVE_ROOT/$relative_path"
        assert_owned_live_symlink "$live_file" "$repo_file"
        if [ -L "$live_file" ] && [ "$(readlink "$live_file")" = "$repo_file" ]; then
            printf '%s: already synchronized\n' "$relative_path"
            continue
        fi
        if [ ! -e "$live_file" ]; then
            printf '%s: missing from live configuration\n' "$relative_path"
            continue
        fi
        copy_atomically "$live_file" "$repo_file"
        rm "$live_file"
        assert_safe_parent "$live_file"
        mkdir -p "$(dirname "$live_file")"
        ln -s "$repo_file" "$live_file"
        printf 'Pulled %s into the repository\n' "$relative_path"
    done
}

pull_new_resources() {
    local directory live_files live_file relative_path repo_file
    live_files="$(mktemp "${TMPDIR:-/tmp}/opencode-sync-new-resources.XXXXXX")"
    trap 'rm -f "$live_files"' RETURN
    for directory in "${RESOURCE_DIRS[@]}"; do
        [ -d "$LIVE_ROOT/$directory" ] || continue
        find "$LIVE_ROOT/$directory" -type f -print0 2>/dev/null > "$live_files"
        while IFS= read -r -d '' live_file; do
            relative_path="${live_file#"$LIVE_ROOT/"}"
            repo_file="$REPO_ROOT/$relative_path"
            [ -e "$repo_file" ] && continue
            validate_new_live_resource "$live_file"
            copy_atomically "$live_file" "$repo_file"
            rm "$live_file"
            assert_safe_parent "$live_file"
            mkdir -p "$(dirname "$live_file")"
            ln -s "$repo_file" "$live_file"
            printf 'Pulled %s into the repository\n' "$relative_path"
        done < "$live_files"
    done
}

pull_all() {
    pull_files
    pull_resources
    pull_new_resources
}

validate_repository_sources() {
    local mapping relative_path repo_file live_file
    for mapping in "${MUTABLE_FILES[@]}"; do
        relative_path="${mapping%%:*}"
        repo_file="$(repo_path_for "$mapping")"
        live_file="$(live_path_for "$mapping")"
        assert_owned_live_symlink "$live_file" "$repo_file"
        [ -f "$repo_file" ] || {
            printf 'Missing repository OpenCode file: %s\n' "$repo_file" >&2
            exit 1
        }
        validate_personal_config "$repo_file"
    done

    local resource_file
    tracked_resource_files | while IFS= read -r -d '' resource_file; do
        relative_path="${resource_file#"$REPO_ROOT/"}"
        live_file="$LIVE_ROOT/$relative_path"
        assert_owned_live_symlink "$live_file" "$resource_file"
        validate_personal_config "$resource_file"
    done
}

push_files() {
    local timestamp mapping relative_path repo_file live_file

    validate_repository_sources
    timestamp="$(date +%Y%m%d%H%M%S)"
    for mapping in "${MUTABLE_FILES[@]}"; do
        relative_path="${mapping%%:*}"
        repo_file="$(repo_path_for "$mapping")"
        live_file="$(live_path_for "$mapping")"
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

push_resources() {
    local timestamp repo_file relative_path live_file

    validate_repository_sources
    timestamp="$(date +%Y%m%d%H%M%S)"
    tracked_resource_files | while IFS= read -r -d '' repo_file; do
        relative_path="${repo_file#"$REPO_ROOT/"}"
        live_file="$LIVE_ROOT/$relative_path"
        if [ -L "$live_file" ] && [ "$(readlink "$live_file")" = "$repo_file" ]; then
            printf '%s: already synchronized\n' "$relative_path"
            continue
        fi
        if [ -e "$live_file" ] && cmp -s "$repo_file" "$live_file"; then
            rm "$live_file"
        elif [ -e "$live_file" ]; then
            backup_live_file "$relative_path" "$timestamp"
        fi
        assert_safe_parent "$live_file"
        mkdir -p "$(dirname "$live_file")"
        ln -s "$repo_file" "$live_file"
        printf 'Pushed %s into the live configuration\n' "$relative_path"
    done
}

push_all() {
    push_files
    push_resources
}

case "${1:-}" in
    status) status_all ;;
    pull) pull_all ;;
    push) push_all ;;
    *) usage; exit 2 ;;
esac
