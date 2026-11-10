"""Tests for lint_skills.py. Each case writes a small, valid skill set to a
temporary directory, breaks one rule in it, and checks what is reported.

  python3 -m unittest discover -s tests
"""
import os
import tempfile
import unittest

import lint_skills

A = "skills/dev-a/SKILL.md"
B = "skills/dev-b/SKILL.md"
S = "evals/s/scenario.md"
SET = {
    "router.md": (
        "# Workflow\n\n## Lanes — the first row that fits\n\n"
        "| Lane | When |\n|---|---|\n| **Planned** | big |\n\n## Terms\n"),
    A: (
        "---\nname: dev-a\ndescription: Does a. Use when a happens.\n---\n\n"
        "## 1. First step\n\nPer *Second step*, and in *Planned* too; "
        "`references/ref.md`, *The brief*.\n\n## Gate 2 — Compliance\n\n"
        "## Second step\n\n```\n## Fenced\n```\n"),
    "skills/dev-a/references/ref.md": "# Ref\n\n## The brief\n",
    B: (
        "---\nname: dev-b\ndescription: Does b. Use when b happens.\n---\n\n"
        "See `dev-a`, *First step*; `dev-a`, *Gate 2*; "
        "`dev-a`'s `references/ref.md`, *The brief*; router, *Terms*.\n"),
    S: (
        "# s\n\nTests: `dev-a`, *Gate 2*, reverse trace 2; router, rule 4 "
        "and *Terms*; `dev-a`'s `references/ref.md`, *The brief*.\n"),
}


class LintSkillsTest(unittest.TestCase):
    def lint(self, path=None, old=None, new=None, extra=None, fn=lint_skills.lint):
        files = {**SET, **(extra or {})}
        if path:
            self.assertIn(old, files[path])
            files[path] = files[path].replace(old, new)
        with tempfile.TemporaryDirectory() as root:
            for rel, text in files.items():
                os.makedirs(os.path.dirname(os.path.join(root, rel)), exist_ok=True)
                with open(os.path.join(root, rel), "w") as f:
                    f.write(text)
            return fn(root)

    def check(self, expected, *args, **kwargs):
        self.assertEqual([v.split(" — ")[0] for v in self.lint(*args, **kwargs)], expected)

    def test_a_valid_set_has_no_violations(self):
        self.assertEqual(self.lint(), [])

    def test_flags_a_skill_without_frontmatter(self):
        self.check([A + ":1: frontmatter", A + ":1: name", A + ":1: description"], A, "---\nname", "name")

    def test_flags_a_frontmatter_key_besides_name_and_description(self):
        self.check([A + ":3: frontmatter"], A, "name: dev-a\n", "name: dev-a\nlicense: MIT\n")

    def test_flags_a_name_that_differs_from_its_folder(self):
        self.check([A + ":2: name"], A, "name: dev-a", "name: dev-x")

    def test_flags_a_name_with_characters_outside_lowercase_digits_and_hyphens(self):
        self.check(["skills/dev_c/SKILL.md:2: name"],
                   extra={"skills/dev_c/SKILL.md": SET[B].replace("dev-b", "dev_c")})

    def test_flags_a_description_over_1024_characters(self):
        self.check([B + ":3: description"], B, "Does b.", "Does b. " + "x" * 1024)

    def test_flags_an_xml_tag_in_a_description(self):
        self.check([B + ":3: description"], B, "Does b.", "Does <b>.")

    def test_flags_a_skill_over_1600_words(self):
        self.check([B + ":1: size"], B, "router, *Terms*.", "router, *Terms*. " + "word " * 1600)

    def test_flags_a_backticked_tool_name(self):
        self.check([B + ":6: tool-name"], B, "See ", "Open it with `Read`. See ")

    def test_flags_a_name_followed_by_the_word_tool(self):
        self.check([B + ":6: tool-name"], B, "See ", "Dispatch the Task tool. See ")

    def test_flags_a_tool_name_that_is_never_an_ordinary_word(self):
        self.check([B + ":6: tool-name"], B, "See ", "Track it in TodoWrite. See ")

    def test_flags_a_backticked_skill_that_does_not_exist(self):
        self.check([B + ":6: reference"], B, "See ", "Unlike `dev-z`. See ")

    def test_flags_a_reference_to_a_section_the_skill_lacks(self):
        self.check([B + ":6: reference"], B, "*First step*", "*Third step*")

    def test_flags_a_reference_to_a_missing_reference_file(self):
        self.check([B + ":6: reference"], B, "references/ref.md`, *The brief*; router",
                   "references/nope.md`, *The brief*; router")

    def test_flags_a_same_file_reference_to_a_missing_section(self):
        self.check([A + ":8: reference"], A, "Per *Second step*", "Per *Third step*")

    def test_flags_every_section_in_a_chained_reference(self):
        self.check([B + ":6: reference"], B, "*First step*;", "*First step*, *Gate 2* and *Third step*;")

    def test_flags_every_section_in_a_chained_same_file_reference(self):
        self.check([A + ":8: reference"], A, "Per *Second step*", "Per *Second step* and *Third step*")

    def test_flags_a_missing_description(self):
        self.check([B + ":3: description"], B, "Does b. Use when b happens.", "")

    def test_flags_a_broken_reference_in_the_repo_agents_file(self):
        self.check(["AGENTS.md:1: reference"], extra={"AGENTS.md": "See `dev-a`, *Third step*.\n"})

    def test_ignores_headings_inside_code_fences(self):
        self.check([A + ":8: reference"], A, "Per *Second step*", "Per *Fenced*")

    def test_flags_an_eval_tests_line_naming_a_missing_section(self):
        self.check([S + ":3: reference"], S, "*Gate 2*", "*Gate 9*")

    def test_flags_an_eval_tests_clause_naming_a_skill_that_does_not_exist(self):
        self.check([S + ":3: reference"], S, "*The brief*.", "*The brief*; `dev-z`.")

    def test_flags_an_eval_tests_clause_naming_no_skill_or_router(self):
        self.check([S + ":3: eval"], S, "; router, rule 4", "; rule 4")

    def test_flags_a_scenario_without_a_tests_line(self):
        self.check([S + ":1: eval"], S, "Tests:", "Test:")

    def test_run_prints_ok_and_exits_0_on_a_valid_set(self):
        self.assertEqual(self.lint(fn=lint_skills.run), ("lint_skills: ok", 0))

    def test_run_prints_each_violation_and_exits_1(self):
        text, code = self.lint(A, "name: dev-a", "name: dev-x", fn=lint_skills.run)
        self.assertEqual((text.split(" — ")[0], code), (A + ":2: name", 1))


if __name__ == "__main__":
    unittest.main()
