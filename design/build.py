#!/usr/bin/env python3
"""Generate themed files from design/tokens.json.

Outputs:
  common/Theme.qml                 the QML singleton every component imports
  <path>  for each design/templates/<path>.tmpl

Templates substitute {{tokenName}} or {{tokenName|format}}. Color formats:
  hex     #rrggbb / #rrggbbaa (default)
  bare    rrggbb / rrggbbaa   (e.g. hyprland rgb(...) / rgba(...))
  rgb     r, g, b             (decimal; alpha dropped)
Easing formats (tokens of type "easing", valued with a Qt Easing name such as "OutCubic"):
  bezier  x1, y1, x2, y2      (cubic-bezier approximation, default; e.g. hyprland bezier, CSS)
  name    OutCubic            (the Qt name)
Number formats:
  ds      milliseconds -> deciseconds (e.g. hyprland animation speed: 300 -> 3)

Usage:
  python3 design/build.py           regenerate everything
  python3 design/build.py --check   exit 1 if any generated file is stale
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DESIGN = ROOT / "design"
TOKENS = DESIGN / "tokens.json"
TEMPLATES = DESIGN / "templates"
THEME_QML = ROOT / "common" / "Theme.qml"

REF = re.compile(r"^\{([A-Za-z][A-Za-z0-9]*)\}$")
HEX = re.compile(r"^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$")
PLACEHOLDER = re.compile(r"\{\{\s*([A-Za-z][A-Za-z0-9]*)\s*(?:\|\s*([a-z]+)\s*)?\}\}")


# Qt easing curves -> cubic-bezier control points (easings.net approximations).
BEZIER = {
    "Linear": (0, 0, 1, 1),
    "InSine": (0.12, 0, 0.39, 0),
    "OutSine": (0.61, 1, 0.88, 1),
    "InOutSine": (0.37, 0, 0.63, 1),
    "InQuad": (0.11, 0, 0.5, 0),
    "OutQuad": (0.5, 1, 0.89, 1),
    "InOutQuad": (0.45, 0, 0.55, 1),
    "InCubic": (0.32, 0, 0.67, 0),
    "OutCubic": (0.33, 1, 0.68, 1),
    "InOutCubic": (0.65, 0, 0.35, 1),
    "InQuart": (0.5, 0, 0.75, 0),
    "OutQuart": (0.25, 1, 0.5, 1),
    "InOutQuart": (0.76, 0, 0.24, 1),
    "InQuint": (0.64, 0, 0.78, 0),
    "OutQuint": (0.22, 1, 0.36, 1),
    "InOutQuint": (0.83, 0, 0.17, 1),
    "InExpo": (0.7, 0, 0.84, 0),
    "OutExpo": (0.16, 1, 0.3, 1),
    "InOutExpo": (0.87, 0, 0.13, 1),
    "InCirc": (0.55, 0, 1, 0.45),
    "OutCirc": (0, 0.55, 0.45, 1),
    "InOutCirc": (0.85, 0, 0.15, 1),
}


class TokenError(Exception):
    pass


def load_tokens():
    """Return (sections, tokens). tokens maps name -> dict(raw, type, mutable, description, section)."""
    data = json.loads(TOKENS.read_text())
    sections = []
    tokens = {}
    for section, entries in data.items():
        if section.startswith("$"):
            continue
        sections.append(section)
        for name, entry in entries.items():
            if name in tokens:
                raise TokenError(f"duplicate token '{name}' in '{section}' (already in '{tokens[name]['section']}')")
            if not isinstance(entry, dict):
                entry = {"value": entry}
            tokens[name] = {
                "raw": entry["value"],
                "type": entry.get("type"),
                "mutable": entry.get("mutable", False),
                "description": entry.get("description"),
                "deprecated": entry.get("deprecated"),
                "section": section,
            }
    return sections, tokens


def resolve(tokens):
    """Fill in 'value', 'ref' and 'type' for every token."""

    def walk(name, chain):
        token = tokens.get(name)
        if token is None:
            raise TokenError(f"unknown token '{name}'" + (f" referenced from '{chain[-1]}'" if chain else ""))
        if "value" in token:
            return token
        if name in chain:
            raise TokenError("reference cycle: " + " -> ".join(chain + [name]))
        raw = token["raw"]
        match = REF.match(raw) if isinstance(raw, str) else None
        if match:
            target = walk(match.group(1), chain + [name])
            token["ref"] = match.group(1)
            token["value"] = target["value"]
            token["type"] = token["type"] or target["type"]
        else:
            token["ref"] = None
            token["value"] = raw
            token["type"] = token["type"] or infer_type(raw)
        if token["type"] == "color":
            token["value"] = normalize_hex(name, token["value"])
        if token["type"] == "easing" and token["value"] not in BEZIER:
            raise TokenError(f"token '{name}': unknown easing '{token['value']}' (known: {', '.join(BEZIER)})")
        return token

    for name in tokens:
        walk(name, [])


def infer_type(value):
    if isinstance(value, bool):
        return "bool"
    if isinstance(value, int):
        return "int"
    if isinstance(value, float):
        return "real"
    if isinstance(value, str) and HEX.match(value):
        return "color"
    return "string"


def normalize_hex(name, value):
    match = HEX.match(str(value))
    if not match:
        raise TokenError(f"token '{name}' is a color but '{value}' is not #RGB/#RRGGBB/#RRGGBBAA")
    digits = match.group(1).lower()
    if len(digits) == 3:
        digits = "".join(c * 2 for c in digits)
    return "#" + digits


def color_qml(value):
    """CSS #rrggbbaa -> QML #aarrggbb."""
    digits = value[1:]
    if len(digits) == 8:
        digits = digits[6:] + digits[:6]
    return "#" + digits


def qml_literal(token):
    value, kind = token["value"], token["type"]
    if kind == "color":
        return json.dumps(color_qml(value))
    if kind == "string":
        return json.dumps(value)
    if kind == "bool":
        return "true" if value else "false"
    if kind == "easing":
        return f"Easing.{value}"
    return repr(value)


QML_TYPES = {"easing": "int"}


def render_theme(sections, tokens):
    lines = [
        "// GENERATED by design/build.py from design/tokens.json. Do not edit by hand.",
        "pragma Singleton",
        "",
        "import QtQuick",
        "import Quickshell",
        "",
        "Singleton {",
    ]
    for section in sections:
        names = [n for n, t in tokens.items() if t["section"] == section]
        if not names:
            continue
        lines += ["", f"    // SECTION {section[:1].upper() + section[1:]}", ""]
        for name in names:
            token = tokens[name]
            if token["deprecated"]:
                lines.append(f"    // DEPRECATED: use {token['deprecated']}")
            elif token["description"]:
                lines.append(f"    // {token['description']}")
            qualifier = "property" if token["mutable"] else "readonly property"
            value = token["ref"] if token["ref"] else qml_literal(token)
            qml_type = QML_TYPES.get(token["type"], token["type"])
            lines.append(f"    {qualifier} {qml_type} {name}: {value}")
    lines += ["}", ""]
    return "\n".join(lines)


def format_value(token, fmt, where):
    value = token["value"]
    if token["type"] == "easing":
        fmt = fmt or "bezier"
        if fmt == "name":
            return value
        if fmt == "bezier":
            return ", ".join(f"{v:g}" for v in BEZIER[value])
        raise TokenError(f"{where}: unknown easing format '{fmt}' (use bezier or name)")
    if fmt == "ds":
        if token["type"] not in ("int", "real"):
            raise TokenError(f"{where}: format 'ds' only applies to numbers")
        return f"{value / 100:g}"
    if token["type"] != "color":
        if fmt:
            raise TokenError(f"{where}: format '{fmt}' only applies to colors, easings and numbers (ds)")
        return str(value).lower() if isinstance(value, bool) else str(value)
    fmt = fmt or "hex"
    if fmt == "hex":
        return value
    if fmt == "bare":
        return value[1:]
    if fmt == "rgb":
        return ", ".join(str(int(value[i:i + 2], 16)) for i in (1, 3, 5))
    raise TokenError(f"{where}: unknown format '{fmt}' (use hex, bare or rgb)")


def render_template(path, tokens):
    rel = path.relative_to(TEMPLATES)

    def substitute(match):
        name, fmt = match.group(1), match.group(2)
        if name not in tokens:
            raise TokenError(f"{rel}: unknown token '{name}'")
        return format_value(tokens[name], fmt, rel)

    return PLACEHOLDER.sub(substitute, path.read_text())


def outputs(sections, tokens):
    yield THEME_QML, render_theme(sections, tokens)
    for template in sorted(TEMPLATES.rglob("*.tmpl")):
        target = ROOT / template.relative_to(TEMPLATES).with_suffix("")
        yield target, render_template(template, tokens)


QML_ROOTS = ("bar", "common", "greeter", "bar.qml", "greeter.qml")


def deprecated_usages(tokens):
    """Yield (path, line number, token, replacement) for each Theme.<deprecated> in QML."""
    names = {n: t["deprecated"] for n, t in tokens.items() if t["deprecated"]}
    if not names:
        return
    pattern = re.compile(r"\bTheme\.(" + "|".join(names) + r")\b")
    files = []
    for root in QML_ROOTS:
        path = ROOT / root
        files += [path] if path.is_file() else sorted(path.rglob("*.qml"))
    for path in files:
        if path == THEME_QML:
            continue
        for number, line in enumerate(path.read_text().splitlines(), 1):
            for match in pattern.finditer(line):
                yield path.relative_to(ROOT), number, match.group(1), names[match.group(1)]


def main():
    check = "--check" in sys.argv[1:]
    try:
        sections, tokens = load_tokens()
        resolve(tokens)
        results = list(outputs(sections, tokens))
    except (TokenError, json.JSONDecodeError, KeyError) as error:
        print(f"[ERROR] {error}", file=sys.stderr)
        return 2

    stale = []
    for target, content in results:
        current = target.read_text() if target.exists() else None
        if current == content:
            continue
        stale.append(target.relative_to(ROOT))
        if not check:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(content)

    usages = list(deprecated_usages(tokens))
    for path, number, name, replacement in usages:
        print(f"[DEPRECATED] {path}:{number} Theme.{name} -> {replacement}", file=sys.stderr)
    if usages:
        print(f"[DEPRECATED] {len(usages)} use(s) of deprecated tokens (warning only)", file=sys.stderr)

    if check:
        for path in stale:
            print(f"[STALE] {path}", file=sys.stderr)
        if stale:
            print("Run: python3 design/build.py", file=sys.stderr)
        return 1 if stale else 0

    for path in stale:
        print(f"[WROTE] {path}")
    if not stale:
        print("Everything up to date.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
