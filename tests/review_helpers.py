"""Shared by the structural tests of the dev-review skill and of the skills that call it."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILL = "skills/dev-review/"

TOOL = re.compile(
    r"\b(TodoWrite|WebFetch|WebSearch|MultiEdit|NotebookEdit|AskUserQuestion"
    r"|EnterPlanMode|ExitPlanMode|apply_patch|update_plan)\b"
    r"|`(Read|Write|Edit|Bash|Grep|Glob|Task|Agent|Skill)`"
    r"|\b(Read|Write|Edit|Bash|Grep|Glob|Task|Agent|Skill) tool\b")


def read(relative):
    """The file's text, or an empty string when it is missing, so a test fails instead of erroring."""
    path = ROOT / relative
    return path.read_text(encoding="utf-8") if path.is_file() else ""


def headings(text):
    """The `## ` headings outside code fences, in order."""
    found, in_fence = [], False
    for line in text.splitlines():
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
        elif not in_fence and line.startswith("## "):
            found.append(line[3:])
    return found


def section(text, heading):
    """The text under `## heading`, up to the next `## ` heading outside a code fence."""
    lines, inside, in_fence = [], False, False
    for line in text.splitlines():
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
        if not in_fence and line.startswith("## "):
            if inside:
                break
            inside = line == "## " + heading
            continue
        if inside:
            lines.append(line)
    return "\n".join(lines)


def fenced(text):
    """The contents of each code fence, in order."""
    blocks, current = [], None
    for line in text.splitlines():
        if line.lstrip().startswith("```"):
            if current is None:
                current = []
            else:
                blocks.append("\n".join(current))
                current = None
        elif current is not None:
            current.append(line)
    return blocks


def tool_names(text):
    return [match.group(0) for match in TOOL.finditer(text)]
