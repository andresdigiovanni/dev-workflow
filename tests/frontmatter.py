#!/usr/bin/env python3
"""Canonical frontmatter for the dispatch-role agent files.

One file per role under agents/. `build_frontmatter` renders one harness's
installed frontmatter from those lines:

- a `model` line holds the `<model>` placeholder, replaced from
  agents/models.toml (the role's entry for this harness, else that
  harness's `default`);
- `tools` is reformatted per harness (omp: lowercase YAML list, claude-code:
  capitalized CSV, opencode: dropped — it reads no tools field);
- an `effort` line holds the `<effort>` placeholder, replaced from the
  `[<harness>.effort]` table of agents/models.toml (the role's entry; none
  leaves the line out), and renders as omp's `thinking-level`, passes as
  claude-code's `effort`, and joins opencode's `model` as a `#variant` (its
  only effort mechanism): `model: openai/gpt-5` + `effort: high` →
  `model: openai/gpt-5#high`;
- `mode` renders only for opencode (its primary/subagent selector);
- the body passes through unchanged.

The `<model>` and `<effort>` placeholders are our installer's convention:
agents/*.md are source files, never installed as-is.
"""
import re
import sys

HARNESSES = ("omp", "opencode", "claude-code", "codex")

TOOL_CAPITALIZE = re.compile(r"[a-z][a-z-]*")
PLACEHOLDER = re.compile(r"^<model>$")
EFFORT_PLACEHOLDER = re.compile(r"^<effort>$")


def parse_models(path):
    """Reads models.toml into {(table, key): value}: a table is a harness
    (`omp`, models by role) or its effort table (`omp.effort`).

    Parses the subset the file uses: `[table]` headers, `key = "string"`
    pairs, `#` comments — enough TOML, no dependency on Python 3.11's
    tomllib, which the system python3 (3.9) lacks.
    """
    table = {}
    harness = None
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = _strip_comment(line).strip()
            if not line:
                continue
            if line.startswith("[") and line.endswith("]"):
                harness = line[1:-1].strip()
                continue
            key, _, value = line.partition("=")
            if harness is None or not _.strip():
                raise ValueError(f"{path}: not a harness table entry: {line}")
            value = value.strip()
            if not (value.startswith('"') and value.endswith('"') and len(value) >= 2):
                raise ValueError(f"{path}: only quoted strings are read: {line}")
            table[(harness, key.strip())] = value[1:-1]
    return table


def _strip_comment(line):
    """The line up to a `#` that is not inside a quoted string."""
    quoted = False
    for i, ch in enumerate(line):
        if ch == '"':
            quoted = not quoted
        elif ch == "#" and not quoted:
            return line[:i]
    return line


def apply_overrides(models, overrides):
    """Sets each `table:role=value` of overrides over the parsed table."""
    for entry in overrides:
        head, eq, value = entry.partition("=")
        table, colon, role = head.partition(":")
        if not (eq and colon and table and role):
            raise ValueError(f"not a table:role=value override: {entry}")
        models[(table, role)] = value
    return models


def table_roles(models, table):
    """The (role, value) pairs of one table, in file order."""
    return [(role, value) for (t, role), value in models.items() if t == table]


def build_frontmatter(fields, harness, body="", models=None, role=None):
    """Renders one harness's agent file for the given canonical fields.

    fields: iterable of (key, value). models: the parsed agents/models.toml
    table, for placeholder resolution; role: the agent role the fields come
    from. Returns the installed file text. Markdown harnesses get a
    frontmatter block plus the body; codex gets a TOML file with the body
    as developer_instructions.
    """
    if harness == "codex":
        return _build_codex_toml(fields, harness, body, models, role)
    lines = []
    model = model_pos = effort = None
    for key, value in fields:
        if key == "model":
            if PLACEHOLDER.match(value) and models is not None:
                value = models.get((harness, role)) or models.get((harness, "default"), "")
            if not value or PLACEHOLDER.match(value):
                continue  # no default for this harness: leave the line out
            model, model_pos = value, len(lines)  # opencode: effort joins it below
            lines.append(None)  # placeholder keeps canonical field order
            continue
        if key == "effort":
            value = _effort(value, harness, models, role)
            if not value:
                continue  # no entry for this role: leave the line out
            if harness == "opencode":
                effort = value
                continue
            key = "thinking-level" if harness == "omp" else key
        elif key == "mode" and harness != "opencode":
            continue
        rendered = _format_value(key, value, harness)
        if rendered is None:
            continue
        if isinstance(rendered, tuple):  # (renamed-key, value)
            key, rendered = rendered
        lines.append(f"{key}: {rendered}")
    if model_pos is not None:
        lines[model_pos] = f"model: {model}#{effort}" if effort else f"model: {model}"
    return "---\n" + "\n".join(l for l in lines if l is not None) + "\n---\n" + body


def _effort(value, harness, models, role):
    """The effort an `effort` line renders as: the `<effort>` placeholder
    resolves to the role's entry in the harness's effort table, else to
    nothing; any other value passes through."""
    if EFFORT_PLACEHOLDER.match(value):
        return (models or {}).get((f"{harness}.effort", role), "")
    return value


def _toml_quote(value):
    """A basic TOML string literal: quotes doubled inside."""
    return '"' + value.replace('"', '""') + '"'


def _build_codex_toml(fields, harness, body, models, role):
    """A Codex custom-agent file: key = "value" lines, the body as a
    developer_instructions multiline string. `model` and `effort` render
    as model and model_reasoning_effort; mode and tools have no Codex
    field and are left out.
    """
    lines = []
    effort = None
    for key, value in fields:
        if key == "model":
            if PLACEHOLDER.match(value) and models is not None:
                value = models.get((harness, role)) or models.get((harness, "default"), "")
            if not value or PLACEHOLDER.match(value):
                continue
            lines.append(f"model = {_toml_quote(value)}")
        elif key == "effort":
            effort = _effort(value, harness, models, role)
        elif key in ("mode", "tools"):
            continue
        else:
            lines.append(f"{key} = {_toml_quote(value)}")
    if effort:
        lines.append(f"model_reasoning_effort = {_toml_quote(effort)}")
    lines.append(f"developer_instructions = \"\"\"\n{body.rstrip()}\"\"\"")
    return "\n".join(lines) + "\n"


def _format_value(key, value, harness):
    if key == "tools":
        if harness == "omp":
            return value
        if harness == "claude-code":
            names = re.findall(r"[a-z-]+", value)
            return ", ".join(TOOL_CAPITALIZE.sub(lambda m: m.group(0).capitalize(), n)
                             for n in names)
        return None  # opencode reads no tools field
    return value


def parse_canonical(path):
    """Reads a canonical agent file into (fields, body)."""
    with open(path, encoding="utf-8") as f:
        text = f.read()
    if not text.startswith("---"):
        raise ValueError(f"{path}: no frontmatter")
    end = text.index("\n---", 3)
    fields = []
    for line in text[4:end].splitlines():
        key, _, value = line.partition(":")
        fields.append((key.strip(), value.strip()))
    return fields, text[end + 5:]


def build_installed(path, harness, models_path=None, overrides=()):
    fields, body = parse_canonical(path)
    models = parse_models(models_path) if models_path else {}
    apply_overrides(models, overrides)
    role = path.rsplit("/", 1)[-1][:-3]
    return build_frontmatter(fields, harness, body=body, models=models, role=role)


USAGE = ("usage: frontmatter.py <canonical-agent.md> <harness> [models.toml] "
         "[--set table:role=value ...]\n"
         "       frontmatter.py --table <models.toml> <table>")


if __name__ == "__main__":
    args = sys.argv[1:]
    if len(args) == 3 and args[0] == "--table":
        for role, value in table_roles(parse_models(args[1]), args[2]):
            print(f"{role}={value}")
        raise SystemExit(0)
    split = args.index("--set") if "--set" in args else len(args)
    positional, sets = args[:split], args[split:]
    if (len(positional) not in (2, 3) or positional[1] not in HARNESSES
            or len(sets) % 2 or any(s != "--set" for s in sets[::2])):
        raise SystemExit(USAGE)
    sys.stdout.write(build_installed(positional[0], positional[1],
                                     models_path=positional[2] if len(positional) == 3 else None,
                                     overrides=sets[1::2]))
