#!/usr/bin/env python3
"""Structural tests for the canonical dispatch-role agent files under agents/.

One file per role — model + a thin contract, no process. Frontmatter lines
carry their harness scope as a trailing comment (`# omp, opencode`); a line
without one applies to every harness. The installer builds each harness's
installed frontmatter from these lines; these tests pin the canonical form
and the builder's output per harness.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tests"))
from frontmatter import build_frontmatter, parse_models  # noqa: E402

AGENTS = os.path.join(ROOT, "agents")

ROLES = ["dev-fact-finder", "dev-builder-check", "dev-implementer", "dev-reviewer",
         "dev-verifier"]

HARNESSES = ["omp", "opencode", "claude-code"]


def canonical_path(role):
    return os.path.join(AGENTS, f"{role}.md")


def parse_lines(path):
    with open(path, encoding="utf-8") as f:
        text = f.read()
    if not text.startswith("---"):
        raise AssertionError(f"{path}: no frontmatter")
    end = text.index("\n---", 3)
    fields = []
    for line in text[4:end].splitlines():
        key, _, value = line.partition(":")
        comment = ""
        if " #" in value:
            value, _, comment = value.partition(" #")
        fields.append((key.strip(), value.strip(),
                       tuple(h.strip() for h in comment.split(",") if h.strip())))
    return fields, text[end + 4:]


class CanonicalFiles(unittest.TestCase):
    def test_role_files_exist_with_valid_frontmatter(self):
        for role in ROLES:
            path = canonical_path(role)
            self.assertTrue(os.path.isfile(path), f"missing {path}")
            fields, body = parse_lines(path)
            by_key = {k: (v, scope) for k, v, scope in fields}
            self.assertIn("name", by_key)
            self.assertEqual(by_key["name"][0], role, f"{path}: name != stem")
            self.assertIn("description", by_key)
            self.assertTrue(by_key["description"][0], f"{path}: empty description")
            self.assertLessEqual(len(by_key["description"][0]), 1024,
                                 f"{path}: description over 1024")
            # Every harness gets a model: a `model` line covering it or an
            # `alias` line scoped to it.
            for harness in HARNESSES:
                covered = any(
                    k in ("model", "alias") and (not scope or harness in scope)
                    for k, _, scope in fields)
                self.assertTrue(covered,
                                f"{path}: no model or alias for {harness}")
            self.assertTrue(body.endswith("\n"), f"{path}: no trailing newline")

    def test_every_agent_file_carries_the_dev_prefix(self):
        names = sorted(f for f in os.listdir(AGENTS) if f.endswith(".md"))
        self.assertEqual(names, sorted(f"{role}.md" for role in ROLES))
        for name in names:
            self.assertTrue(name.startswith("dev-"), f"{name}: no dev- prefix")

    def test_scopes_name_known_harnesses(self):
        for role in ROLES:
            fields, _ = parse_lines(canonical_path(role))
            for key, _, scope in fields:
                for harness in scope:
                    self.assertIn(harness, HARNESSES,
                                  f"{role}: {key} names unknown harness {harness}")

    def test_bodies_name_no_tool(self):
        tool = re.compile(r"\b(TODO|task tool|Task tool|TASK\b|Read tool|"
                          r"Grep tool|Bash tool|`Task`|`Grep`|`Bash`)\b")
        for role in ROLES:
            _, body = parse_lines(canonical_path(role))
            self.assertIsNone(tool.search(body), f"{role}: body names a tool")

    def test_report_shape_belongs_to_the_skill(self):
        # A skill's coordinator parses these roles' reports, so the shape
        # lives in the brief it sends; a second copy here would compete with
        # it. dev-fact-finder is exempt: no skill defines its shape.
        for role in ROLES:
            if role == "dev-fact-finder":
                continue
            _, body = parse_lines(canonical_path(role))
            self.assertNotIn("```", body,
                             f"{role}: body carries a report shape the brief owns")


class Builder(unittest.TestCase):
    def test_plain_lines_reach_every_harness(self):
        out = build_frontmatter(
            [("name", "reviewer"), ("description", "d")], "omp")
        self.assertIn("name: reviewer", out)
        self.assertIn("description: d", build_frontmatter(
            [("name", "reviewer"), ("description", "d")], "opencode"))

    def test_harness_specific_fields_render_only_their_harness(self):
        fields = [("effort", "high"), ("mode", "subagent")]
        omp = build_frontmatter(fields, "omp")
        oc = build_frontmatter(fields, "opencode")
        cc = build_frontmatter(fields, "claude-code")
        cx = build_frontmatter(fields, "codex")
        self.assertIn("thinking-level: high", omp)
        self.assertNotIn("effort", omp)
        self.assertNotIn("effort", oc)
        self.assertNotIn("thinking-level", oc)
        self.assertIn("effort: high", cc)
        self.assertIn("mode: subagent", oc)
        self.assertNotIn("mode:", omp)
        self.assertNotIn("mode:", cc)
        self.assertIn('model_reasoning_effort = "high"', cx)
        self.assertNotIn("mode:", cx)
        self.assertNotIn("mode = ", cx)

    def test_codex_renders_toml_with_body_as_instructions(self):
        fields = [("name", "reviewer"), ("description", 'has "quotes" and $dollar'),
                  ("model", "<model>"), ("effort", "high"),
                  ("mode", "subagent"), ("tools", "[read, grep]")]
        table = {("codex", "default"): "gpt-6.2-sol"}
        out = build_frontmatter(fields, "codex", body="Line one.\n\nLine two.\n",
                                models=table, role="reviewer")
        self.assertIn('name = "reviewer"', out)
        self.assertIn('description = "has ""quotes"" and $dollar"', out)
        self.assertIn('model = "gpt-6.2-sol"', out)
        self.assertIn('model_reasoning_effort = "high"', out)
        self.assertNotIn("mode:", out)
        self.assertNotIn("mode = ", out)
        self.assertNotIn("tools", out)
        self.assertIn('developer_instructions = """\nLine one.\n\nLine two."""', out)
        self.assertTrue(out.endswith('"""\n'))

    def test_model_placeholder_resolves_per_harness(self):
        fields = [("model", "<model>")]
        table = {("omp", "default"): "openai/gpt-5-mini",
                 ("omp", "reviewer"): "openai/gpt-5",
                 ("opencode", "default"): "openai/gpt-5",
                 ("claude-code", "default"): "claude-sonnet-5-5"}
        omp = build_frontmatter(fields, "omp", models=table, role="reviewer")
        oc = build_frontmatter(fields, "opencode", models=table, role="reviewer")
        cc = build_frontmatter(fields, "claude-code", models=table, role="reviewer")
        self.assertIn("model: openai/gpt-5\n", omp)  # role entry beats default
        self.assertIn("model: openai/gpt-5", oc)
        self.assertIn("model: claude-sonnet-5-5", cc)
        self.assertNotIn("<", omp + oc + cc)

    def test_missing_default_leaves_model_out(self):
        fields = [("model", "<model>")]
        self.assertEqual(
            build_frontmatter(fields, "opencode",
                              models={("omp", "default"): "m"}, role="reviewer"),
            "---\n\n---\n")

    def test_effort_joins_opencode_model_as_variant(self):
        fields = [("model", "<model>"), ("effort", "high")]
        table = {("opencode", "default"): "openai/gpt-5"}
        out = build_frontmatter(fields, "opencode", models=table, role="reviewer")
        self.assertIn("model: openai/gpt-5#high", out)
        self.assertNotIn("effort", out)

    def test_effort_placeholder_resolves_per_harness(self):
        fields = [("model", "<model>"), ("effort", "<effort>")]
        table = {("omp", "default"): "m", ("omp.effort", "reviewer"): "xhigh",
                 ("opencode", "default"): "openai/gpt-5",
                 ("opencode.effort", "reviewer"): "xhigh",
                 ("claude-code", "default"): "m",
                 ("claude-code.effort", "reviewer"): "medium",
                 ("codex", "default"): "m", ("codex.effort", "reviewer"): "max"}
        omp = build_frontmatter(fields, "omp", models=table, role="reviewer")
        oc = build_frontmatter(fields, "opencode", models=table, role="reviewer")
        cc = build_frontmatter(fields, "claude-code", models=table, role="reviewer")
        cx = build_frontmatter(fields, "codex", models=table, role="reviewer")
        self.assertIn("thinking-level: xhigh", omp)
        self.assertIn("model: openai/gpt-5#xhigh", oc)
        self.assertIn("effort: medium", cc)
        self.assertIn('model_reasoning_effort = "max"', cx)
        self.assertNotIn("<", omp + oc + cc + cx)

    def test_missing_effort_entry_leaves_effort_out(self):
        fields = [("model", "<model>"), ("effort", "<effort>")]
        for harness in ("omp", "opencode", "claude-code", "codex"):
            out = build_frontmatter(fields, harness,
                                    models={(harness, "default"): "m"},
                                    role="reviewer")
            self.assertNotIn("effort", out, harness)
            self.assertNotIn("thinking-level", out, harness)
            self.assertNotIn("#", out, harness)

    def test_claude_tools_are_capitalized_csv(self):
        fields = [("tools", "[read, grep, glob]")]
        out = build_frontmatter(fields, "claude-code")
        self.assertIn("tools: Read, Grep, Glob", out)
        omp = build_frontmatter(fields, "omp")
        self.assertIn("tools: [read, grep, glob]", omp)
        self.assertEqual(build_frontmatter(fields, "opencode"), "---\n\n---\n")

    def test_body_passes_through_unchanged(self):
        body = "\nYou review the change the brief names.\n"
        out = build_frontmatter(
            [("name", "r"), ("description", "d"), ("model", "m")], "omp", body=body)
        self.assertTrue(out.endswith(body))


class ModelsFile(unittest.TestCase):
    """tests/frontmatter.py is the only reader of models.toml."""

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.models = os.path.join(self.tmp, "models.toml")
        with open(self.models, "w", encoding="utf-8") as f:
            f.write('[omp]  # the default harness\n'
                    'default = "m"\n'
                    'reviewer = "x/y"  # tuned\n\n'
                    '[omp.effort]\nreviewer = "low"\n')

    def tearDown(self):
        shutil.rmtree(self.tmp)

    def builder(self, *args):
        return subprocess.run([sys.executable, os.path.join(ROOT, "tests", "frontmatter.py"),
                               *args], capture_output=True, text=True)

    def test_trailing_comment_after_a_quoted_value_is_read(self):
        table = parse_models(self.models)
        self.assertEqual(table[("omp", "reviewer")], "x/y")
        self.assertEqual(table[("omp", "default")], "m")

    def test_table_lists_the_roles_of_one_table_with_their_values(self):
        out = self.builder("--table", self.models, "omp")
        self.assertEqual(out.returncode, 0, out.stderr)
        self.assertEqual(out.stdout.splitlines(), ["default=m", "reviewer=x/y"])
        out = self.builder("--table", self.models, "omp.effort")
        self.assertEqual(out.stdout.splitlines(), ["reviewer=low"])

    def test_set_overrides_beat_the_file_at_build_time(self):
        out = self.builder(canonical_path("dev-reviewer"), "omp", self.models,
                           "--set", "omp:dev-reviewer=other/model",
                           "--set", "omp.effort:dev-reviewer=max")
        self.assertEqual(out.returncode, 0, out.stderr)
        self.assertIn("model: other/model\n", out.stdout)
        self.assertIn("thinking-level: max\n", out.stdout)


class ShippedModels(unittest.TestCase):
    def test_verifier_runs_on_a_different_family_than_the_reviewer_where_several_providers_exist(self):
        table = parse_models(os.path.join(AGENTS, "models.toml"))
        for harness in ("omp", "opencode"):
            reviewer = table[(harness, "dev-reviewer")].split("/")[0]
            verifier = table[(harness, "dev-verifier")].split("/")[0]
            self.assertNotEqual(reviewer, verifier, harness)


class LinterAgentRules(unittest.TestCase):
    """The linter's agent rules, exercised on a doctored copy of the repo."""

    def setUp(self):
        import shutil
        import subprocess
        import tempfile
        self.tmp = tempfile.mkdtemp()
        target = os.path.join(self.tmp, "repo")
        shutil.copytree(ROOT, target,
                        ignore=shutil.ignore_patterns(".git", ".dev-runs"))
        self.repo = target
        self.run_lint = lambda: subprocess.run(
            ["python3", os.path.join(target, "tests", "lint_skills.py")],
            capture_output=True, text=True, cwd=target)

    def tearDown(self):
        import shutil
        shutil.rmtree(self.tmp)

    def doctored(self, name, old, new):
        path = os.path.join(self.repo, "agents", name)
        with open(path, encoding="utf-8") as f:
            text = f.read()
        self.assertIn(old, text)
        with open(path, "w", encoding="utf-8") as f:
            f.write(text.replace(old, new, 1))

    def test_unmodelled_placeholder_flagged(self):
        self.doctored("dev-reviewer.md", "model: <model>", "model: openai/gpt-5")
        out = self.run_lint()
        self.assertIn("write the <model> placeholder", out.stdout + out.stderr)

    def test_literal_effort_flagged(self):
        self.doctored("dev-reviewer.md", "effort: <effort>", "effort: high")
        out = self.run_lint()
        self.assertIn("write the <effort> placeholder", out.stdout + out.stderr)

    def test_missing_effort_entry_flagged(self):
        path = os.path.join(self.repo, "agents", "models.toml")
        with open(path, encoding="utf-8") as f:
            text = f.read()
        start = text.index("[omp.effort]")
        end = text.index("[", start + 1)
        with open(path, "w", encoding="utf-8") as f:
            f.write(text[:start] + text[end:])  # drop the omp effort table
        out = self.run_lint()
        self.assertIn("no models.toml effort entry for dev-reviewer under omp",
                      out.stdout + out.stderr)

    def test_missing_models_entry_flagged(self):
        path = os.path.join(self.repo, "agents", "models.toml")
        with open(path, encoding="utf-8") as f:
            text = f.read()
        start = text.index("[omp]")
        end = text.index("[", start + 1)
        with open(path, "w", encoding="utf-8") as f:
            f.write(text[:start] + text[end:])  # drop the whole omp section
        out = self.run_lint()
        self.assertIn("no models.toml entry for dev-reviewer under omp",
                      out.stdout + out.stderr)

    def test_tool_name_in_body_flagged(self):
        self.doctored("dev-verifier.md", "open the code",
                      "run the `Task` tool on the code")
        out = self.run_lint()
        self.assertIn("tool-name", out.stdout + out.stderr)

    def test_clean_tree_passes(self):
        out = self.run_lint()
        self.assertEqual(out.returncode, 0,
                         f"clean tree flagged: {out.stdout}{out.stderr}")

    def test_name_that_differs_from_the_file_flagged(self):
        self.doctored("dev-reviewer.md", "name: dev-reviewer", "name: other")
        out = self.run_lint()
        self.assertIn("agents/dev-reviewer.md:2: name — 'other'", out.stdout + out.stderr)

    def test_missing_model_line_flagged(self):
        self.doctored("dev-reviewer.md", "model: <model>\n", "")
        out = self.run_lint()
        self.assertIn("no model: <model> line", out.stdout + out.stderr)

    def test_empty_field_flagged(self):
        self.doctored("dev-reviewer.md", "mode: subagent", "mode:")
        out = self.run_lint()
        self.assertIn("mode: empty", out.stdout + out.stderr)


if __name__ == "__main__":
    unittest.main()
