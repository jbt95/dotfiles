#!/usr/bin/env python3
"""Reject known company markers from personal configuration files."""

from __future__ import annotations

import re
import sys
from pathlib import Path

MARKERS = (
    "can" + "da",
    "can" + "da-services",
    "j.bermejo@" + "can" + "da.com",
    "ILC" + "_",
    "Zsc" + "aler",
    "ilc-agent-" + "toolkit",
    "CORPORATE" + "_CA_FILE",
)
MARKER = re.compile("|".join(re.escape(marker) for marker in MARKERS), re.IGNORECASE)


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: python3 validate-personal-config.py FILE_PATH", file=sys.stderr)
        return 2

    path = Path(sys.argv[1])
    try:
        with path.open(encoding="utf-8") as source:
            matches = [number for number, line in enumerate(source, 1) if MARKER.search(line)]
    except (OSError, UnicodeError):
        print(str(path), file=sys.stderr)
        return 1

    if matches:
        for number in matches:
            print(f"{path}:{number}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
