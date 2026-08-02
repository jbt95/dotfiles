#!/usr/bin/env python3
"""Reject literal credentials from portable MCP JSON configuration."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from urllib.parse import unquote

REFERENCE = re.compile(
    r"^(?:\$\{[A-Z][A-Z0-9_]*\}|\{(?:env|file):[^{}\n]+\})$"
)
REFERENCE_PART = re.compile(
    r"(?:\$\{[A-Z][A-Z0-9_]*\}|\{(?:env|file):[^{}\n]+\})"
)
SENSITIVE_NAME = re.compile(
    r"(?:token|secret|authorization|api[-_]?key|password|credential|"
    r"private[-_]?key|access[-_]?key|client[-_]?secret|email|"
    r"username|user[-_]?name)",
    re.IGNORECASE,
)
SENSITIVE_FLAG = re.compile(
    r"^--?(?:api[-_]?key|token|secret|password|authorization|credential|"
    r"private[-_]?key|access[-_]?key|email|username|user[-_]?name)(?:=|$)",
    re.IGNORECASE,
)
SENSITIVE_HEADER = re.compile(
    r"^(?:authorization|proxy-authorization|x-api-key|api-key|"
    r"x-auth-token|x-access-token|x-[a-z0-9-]*(?:token|key|secret|"
    r"password|credential|email))$",
    re.IGNORECASE,
)
PORTABLE_HEADER = re.compile(
    r"^(?:(?:basic|bearer)\s+)?"
    r"(?:\$\{[A-Z][A-Z0-9_]*\}|\{(?:env|file):[^{}\n]+\})$",
    re.IGNORECASE,
)
QUERY_CREDENTIAL = re.compile(
    r"(?:[?&])(?:api[-_]?key|token|secret|password|authorization|"
    r"credential|email|username)="
    r"([^&#]*)",
    re.IGNORECASE,
)


def location(parent: str, key: str | int) -> str:
    if isinstance(key, int):
        return f"{parent}[{key}]"
    return f"{parent}.{key}" if parent else key


def is_reference(value: object) -> bool:
    return isinstance(value, str) and REFERENCE.fullmatch(value) is not None


def require_reference(value: object, path: str, unsafe: set[str]) -> None:
    if isinstance(value, str):
        if not is_reference(value):
            unsafe.add(path)
        return
    if isinstance(value, dict):
        if not value:
            unsafe.add(path)
            return
        for key, child in value.items():
            require_reference(child, location(path, key), unsafe)
        return
    if isinstance(value, list):
        if not value:
            unsafe.add(path)
            return
        for index, child in enumerate(value):
            require_reference(child, location(path, index), unsafe)
        return
    unsafe.add(path)


def inspect_header(value: str, path: str, unsafe: set[str]) -> None:
    header_name, separator, header_value = value.partition(":")
    if separator and SENSITIVE_HEADER.fullmatch(header_name.strip()):
        if PORTABLE_HEADER.fullmatch(header_value.strip()) is None:
            unsafe.add(path)


def inspect_arguments(arguments: list[object], path: str, unsafe: set[str]) -> None:
    for index, argument in enumerate(arguments):
        if not isinstance(argument, str):
            unsafe.add(location(path, index))
            continue
        if argument in ("-H", "--header"):
            if index + 1 >= len(arguments) or not isinstance(arguments[index + 1], str):
                unsafe.add(location(path, index))
            else:
                inspect_header(arguments[index + 1], location(path, index + 1), unsafe)
            continue
        if argument.startswith("--header="):
            inspect_header(argument.split("=", 1)[1], location(path, index), unsafe)
            continue
        if not SENSITIVE_FLAG.match(argument):
            continue
        if "=" in argument:
            require_reference(argument.split("=", 1)[1], location(path, index), unsafe)
        elif index + 1 >= len(arguments):
            unsafe.add(location(path, index))
        else:
            require_reference(arguments[index + 1], location(path, index + 1), unsafe)


def inspect_string(value: str, path: str, unsafe: set[str]) -> None:
    inspect_header(value, path, unsafe)
    if re.match(r"^(?:basic|bearer)\s+", value, re.IGNORECASE):
        if PORTABLE_HEADER.fullmatch(value.strip()) is None:
            unsafe.add(path)
    if value.startswith("--header="):
        header_value = value.split("=", 1)[1]
        if PORTABLE_HEADER.fullmatch(header_value.partition(":")[2].strip()) is not None:
            return
    if SENSITIVE_FLAG.match(value) and "=" in value:
        if is_reference(value.split("=", 1)[1]):
            return
    query_matches = list(QUERY_CREDENTIAL.finditer(value))
    for match in query_matches:
        query_value = unquote(match.group(1))
        if not is_reference(query_value):
            unsafe.add(path)
    references = list(REFERENCE_PART.finditer(value))
    if references and REFERENCE.fullmatch(value) is None:
        if query_matches and all(
            is_reference(unquote(match.group(1))) for match in query_matches
        ):
            return
        header_value = value.partition(":")[2].strip() if ":" in value else ""
        if not PORTABLE_HEADER.fullmatch(value.strip()) and not (
            header_value and PORTABLE_HEADER.fullmatch(header_value) is not None
        ):
            unsafe.add(path)


def walk(value: object, path: str, unsafe: set[str]) -> None:
    if isinstance(value, dict):
        for key, child in value.items():
            child_path = location(path, key)
            if not path.endswith(".mcpServers") and path != "mcpServers" and SENSITIVE_NAME.search(key):
                if SENSITIVE_HEADER.fullmatch(key) and isinstance(child, str):
                    if PORTABLE_HEADER.fullmatch(child.strip()) is None:
                        unsafe.add(child_path)
                else:
                    require_reference(child, child_path, unsafe)
            if key == "args" and isinstance(child, list):
                inspect_arguments(child, child_path, unsafe)
            if key == "env" and isinstance(child, dict):
                for env_name, env_value in child.items():
                    if SENSITIVE_NAME.search(env_name):
                        require_reference(
                            env_value,
                            location(child_path, env_name),
                            unsafe,
                        )
            walk(child, child_path, unsafe)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            walk(child, location(path, index), unsafe)
    elif isinstance(value, str):
        inspect_string(value, path, unsafe)


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: python3 validate-portable-mcp.py JSON_PATH", file=sys.stderr)
        return 2

    path = Path(sys.argv[1])
    try:
        with path.open(encoding="utf-8") as source:
            data = json.load(source)
    except (OSError, UnicodeError, json.JSONDecodeError):
        print(f"invalid JSON: {path}", file=sys.stderr)
        return 1

    unsafe: set[str] = set()
    walk(data, "$", unsafe)
    if unsafe:
        print("unsafe sensitive JSON locations:", file=sys.stderr)
        for item in sorted(unsafe):
            print(item, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
