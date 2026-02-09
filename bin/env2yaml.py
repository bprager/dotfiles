#!/usr/bin/env python3
"""
env2yaml.py

Convert a .env file (KEY=VALUE lines) into a YAML mapping, suitable for SOPS.

Features:
- Supports: KEY=VALUE, export KEY=VALUE
- Ignores blank lines and comments (# ...) outside of quotes
- Preserves strings (writes quoted YAML scalars), keeps empty values as ""
- Writes output YAML to stdout or a file
- Optional: output nested YAML from keys containing "__" (double underscore)

Examples:
  python env2yaml.py .env > secrets.yaml
  python env2yaml.py .env -o secrets.yaml
  python env2yaml.py .env --nested --sep "__" -o secrets.yaml
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Any, Dict, Tuple


_KEY_RE = re.compile(r"^(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$")


def strip_inline_comment(value: str) -> str:
    """
    Remove inline comments starting with #, but only when # is not inside single/double quotes.
    """
    in_squote = False
    in_dquote = False
    out = []
    i = 0
    while i < len(value):
        ch = value[i]
        if ch == "'" and not in_dquote:
            in_squote = not in_squote
            out.append(ch)
        elif ch == '"' and not in_squote:
            in_dquote = not in_dquote
            out.append(ch)
        elif ch == "#" and not in_squote and not in_dquote:
            break
        else:
            out.append(ch)
        i += 1
    return "".join(out).rstrip()


def unquote_env_value(value: str) -> str:
    """
    If value is wrapped in single or double quotes, remove wrapping quotes.
    For double quotes, interpret common escapes (\n, \t, \r, \", \\).
    For single quotes, keep content literally (bash-style).
    """
    v = value.strip()
    if len(v) >= 2 and ((v[0] == v[-1] == '"') or (v[0] == v[-1] == "'")):
        quote = v[0]
        inner = v[1:-1]
        if quote == '"':
            # Minimal escape handling (not full shell parsing)
            inner = (
                inner.replace(r"\\", "\\")
                .replace(r"\"", '"')
                .replace(r"\n", "\n")
                .replace(r"\t", "\t")
                .replace(r"\r", "\r")
            )
        return inner
    return v


def parse_env_line(line: str, lineno: int) -> Tuple[str, str] | None:
    raw = line.rstrip("\n")
    s = raw.strip()
    if not s:
        return None
    if s.startswith("#"):
        return None

    m = _KEY_RE.match(s)
    if not m:
        raise ValueError(f"Line {lineno}: not a KEY=VALUE assignment: {raw!r}")

    key = m.group(1)
    rest = m.group(2)

    rest = strip_inline_comment(rest)
    value = unquote_env_value(rest)

    return key, value


def set_nested(d: Dict[str, Any], path: Tuple[str, ...], value: Any) -> None:
    cur: Dict[str, Any] = d
    for part in path[:-1]:
        if part not in cur:
            cur[part] = {}
        elif not isinstance(cur[part], dict):
            raise ValueError(f"Cannot nest into '{part}': existing value is not a mapping")
        cur = cur[part]
    leaf = path[-1]
    if leaf in cur:
        raise ValueError(f"Duplicate key after nesting: {'.'.join(path)}")
    cur[leaf] = value


def yaml_quote(s: str) -> str:
    """
    Always emit YAML double-quoted scalars for safety.
    """
    s = s.replace("\\", "\\\\").replace('"', '\\"')
    s = s.replace("\n", "\\n").replace("\t", "\\t").replace("\r", "\\r")
    return f'"{s}"'


def dump_yaml(data: Dict[str, Any], indent: int = 2, level: int = 0) -> str:
    """
    Minimal YAML dumper for mappings with string keys and values or nested mappings.
    """
    lines: list[str] = []
    pad = " " * (indent * level)
    for k in sorted(data.keys()):
        v = data[k]
        if isinstance(v, dict):
            lines.append(f"{pad}{k}:")
            lines.append(dump_yaml(v, indent=indent, level=level + 1))
        else:
            lines.append(f"{pad}{k}: {yaml_quote(str(v))}")
    return "\n".join(lines)


def main() -> int:
    ap = argparse.ArgumentParser(description="Convert a .env file into YAML (for SOPS).")
    ap.add_argument("env_file", type=Path, help="Path to .env file")
    ap.add_argument("-o", "--out", type=Path, default=None, help="Output YAML file (default: stdout)")
    ap.add_argument("--nested", action="store_true", help="Convert keys with separator into nested YAML")
    ap.add_argument("--sep", default="__", help="Separator for nesting when --nested is used (default: __)")
    ap.add_argument("--indent", type=int, default=2, help="YAML indent spaces (default: 2)")
    args = ap.parse_args()

    if not args.env_file.exists():
        print(f"Error: file not found: {args.env_file}", file=sys.stderr)
        return 2

    root: Dict[str, Any] = {}
    with args.env_file.open("r", encoding="utf-8") as f:
        for i, line in enumerate(f, start=1):
            parsed = parse_env_line(line, i)
            if parsed is None:
                continue
            key, value = parsed

            if args.nested and args.sep in key:
                path = tuple(part for part in key.split(args.sep) if part)
                if not path:
                    raise ValueError(f"Line {i}: invalid nested key: {key!r}")
                set_nested(root, path, value)
            else:
                if key in root:
                    raise ValueError(f"Line {i}: duplicate key: {key}")
                root[key] = value

    yaml_text = dump_yaml(root, indent=args.indent).rstrip() + "\n"

    if args.out:
        args.out.write_text(yaml_text, encoding="utf-8")
    else:
        sys.stdout.write(yaml_text)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

