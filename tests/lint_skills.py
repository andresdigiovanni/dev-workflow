#!/usr/bin/env python3
"""Checks the rules of AGENTS.md that a script can check: each skill's
frontmatter, name, description and size; tool names; and every reference
to a skill, a reference file or a section heading, in the router,
AGENTS.md, the skills and the evals' Tests: lines.

  python3 tests/lint_skills.py

Prints one line per violation, `path:line: rule — detail`, and exits 1
when there is any.
"""
import glob
import os
import re
import sys

MAX_WORDS = 1600
MAX_DESCRIPTION = 1024
NAME = re.compile(r"[a-z0-9]+(-[a-z0-9]+)*")
TOOL = re.compile(
    r"\b(TodoWrite|WebFetch|WebSearch|MultiEdit|NotebookEdit|AskUserQuestion"
    r"|EnterPlanMode|ExitPlanMode|apply_patch|update_plan)\b"
    r"|`(Read|Write|Edit|Bash|Grep|Glob|Task|Agent|Skill)`"
    r"|\b(Read|Write|Edit|Bash|Grep|Glob|Task|Agent|Skill) tool\b")
SKILL = re.compile(r"`(dev-[a-z0-9-]+)`")
CHAIN = r"\*([^*]+)\*((?:(?:, and|,| and) \*[^*]+\*)*)"
SECTION = re.compile(r"(?:`(dev-[a-z0-9-]+)`(?:'s)? ?)?(?:`(references/[a-z0-9-]+\.md)`)?"
                     r"(router)?, " + CHAIN)
LOCAL = re.compile(r"\b(?:per|in) " + CHAIN, re.I)
CLAUSE = re.compile(r"\s*(?:`(dev-[a-z0-9-]+)`(?:'s `(references/[a-z0-9-]+\.md)`)?|(router)\b)")


def prose(text):
    """Yields (line number, line) for every line outside a code fence."""
    fence = None
    for n, line in enumerate(text.splitlines(), 1):
        m = re.match(r"\s*(`{3,})", line)
        if m and fence is None:
            fence = m.group(1)
        elif m and len(m.group(1)) >= len(fence) and line.strip() == m.group(1):
            fence = None
        elif fence is None:
            yield n, line


def has_section(text, ref):
    for _, line in prose(text):
        m = re.match(r"#{1,6} +(?:\d+\. +)?(.+?)\s*$", line)
        if m and ref in (m.group(1), m.group(1).split(" — ")[0]):
            return True
    return False


def lint(root):
    found, cache = [], {}

    def read(path):
        if path not in cache:
            with open(path) as f:
                cache[path] = f.read()
        return cache[path]

    def flag(path, n, rule, detail):
        found.append(f"{os.path.relpath(path, root)}:{n}: {rule} — {detail}")

    def check(path, n, target, ref):
        if not os.path.isfile(target):
            flag(path, n, "reference", f"no file {os.path.relpath(target, root)}")
        elif not has_section(read(target), ref):
            flag(path, n, "reference", f"no section *{ref}* in {os.path.relpath(target, root)}")

    router = os.path.join(root, "router.md")
    skills_dir = os.path.join(root, "skills")
    skills = sorted(os.path.basename(os.path.dirname(p))
                    for p in glob.glob(os.path.join(skills_dir, "*", "SKILL.md")))
    lanes = set(re.findall(r"^\| \*\*(\w+)\*\* \|", read(router), re.M))

    for name in skills:
        path = os.path.join(skills_dir, name, "SKILL.md")
        lines = read(path).splitlines()
        end = lines.index("---", 1) if lines[:1] == ["---"] and "---" in lines[1:] else 0
        if not end:
            flag(path, 1, "frontmatter", "no --- block at the top")
        fields = {}
        for n in range(2, end + 1):
            key, _, value = lines[n - 1].partition(":")
            fields[key] = (n, value.strip())
            if key not in ("name", "description"):
                flag(path, n, "frontmatter", f"{key!r}: only name and description")
        n, value = fields.get("name", (1, ""))
        if value != name or not NAME.fullmatch(name) or len(name) > 64:
            flag(path, n, "name", f"{value!r}: matches the folder, lowercase letters, "
                                  "digits and single hyphens, at most 64")
        n, value = fields.get("description", (1, ""))
        if not value:
            flag(path, n, "description", "missing or empty")
        if len(value) > MAX_DESCRIPTION:
            flag(path, n, "description", f"{len(value)} characters, over {MAX_DESCRIPTION}")
        if re.search(r"<[A-Za-z/][^>]*>", value):
            flag(path, n, "description", "contains an XML tag")
        words = len(read(path).split())
        if words > MAX_WORDS:
            flag(path, 1, "size", f"{words} words, over {MAX_WORDS}")

    agents = os.path.join(root, "AGENTS.md")
    files = [router] + ([agents] if os.path.isfile(agents) else []) + sorted(glob.glob(os.path.join(skills_dir, "*", "SKILL.md"))
                              + glob.glob(os.path.join(skills_dir, "*", "references", "*.md")))
    for path in files:
        own = os.path.basename(os.path.dirname(path)) if path.endswith("SKILL.md") else \
            os.path.basename(os.path.dirname(os.path.dirname(path)))
        for n, line in enumerate(read(path).splitlines(), 1):
            for m in TOOL.finditer(line):
                flag(path, n, "tool-name", f"{m.group(0)}: write the action, not the tool")
        for n, line in prose(read(path)):
            for skill in SKILL.findall(line):
                if skill not in skills:
                    flag(path, n, "reference", f"no skill `{skill}`")
            for skill, ref_file, is_router, ref, chain in SECTION.findall(line):
                target = router if is_router else \
                    os.path.join(skills_dir, skill or own, ref_file or "SKILL.md")
                for each in [ref] + re.findall(r"\*([^*]+)\*", chain):
                    if is_router or skill or ref_file:
                        check(path, n, target, each)
            for ref, chain in LOCAL.findall(line):
                for each in [ref] + re.findall(r"\*([^*]+)\*", chain):
                    if each not in lanes:
                        check(path, n, path, each)

    for path in sorted(glob.glob(os.path.join(root, "evals", "*", "scenario.md"))):
        tests = [(n, line) for n, line in enumerate(read(path).splitlines(), 1)
                 if line.startswith("Tests:")]
        if not tests:
            flag(path, 1, "eval", "no Tests: line")
        for n, line in tests:
            for clause in line[len("Tests:"):].split(";"):
                m = CLAUSE.match(clause)
                if not m:
                    flag(path, n, "eval", f"names no skill or router: {clause.strip()}")
                    continue
                skill, ref_file, is_router = m.groups()
                target = router if is_router else \
                    os.path.join(skills_dir, skill, ref_file or "SKILL.md")
                if not os.path.isfile(target):
                    flag(path, n, "reference", f"no file {os.path.relpath(target, root)}")
                    continue
                for ref in re.findall(r"\*([^*]+)\*", clause):
                    check(path, n, target, ref)
    return found


def run(root):
    found = lint(root)
    return ("\n".join(found), 1) if found else ("lint_skills: ok", 0)


if __name__ == "__main__":
    text, code = run(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    print(text)
    sys.exit(code)
