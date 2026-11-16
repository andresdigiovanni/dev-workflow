import re
import unittest

import review_helpers as helpers

DESCRIPTION = (
    "Judges a change and reports what it finds, without modifying anything. Use before "
    "committing the last task of a change, before reporting work complete, fixed or passing, "
    "before opening a PR or merging, and once after each slice of a plan. Also use when the user "
    "asks to review a change (uncommitted work, a branch, a commit range, a pull request or code "
    "they point to, theirs or someone else's) or asks whether it is correct, safe to merge, well "
    "tested or does what was asked. On the Trivial lane, only where dev-ship sends it here. Not "
    "for measuring a test suite or auditing a whole codebase."
)
HEADINGS = [
    "Rules", "1. Target", "2. Context", "3. Triage", "4. Checks", "5. Review", "6. Verify",
    "7. Report", "Without sub-agents",
]
REFERENCES = ["checks.md", "report.md", "reviewers.md", "target.md", "verifier.md"]


class Skill(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = helpers.read(helpers.SKILL + "SKILL.md")
        front = cls.text.split("---\n")[1] if cls.text.startswith("---\n") else ""
        cls.fields = dict(line.split(": ", 1) for line in front.splitlines() if ": " in line)

    def test_frontmatter_is_name_and_description_only(self):
        self.assertEqual(sorted(self.fields), ["description", "name"])
        self.assertEqual(self.fields["name"], "dev-review")

    def test_description_is_the_contract(self):
        description = self.fields.get("description", "")
        self.assertEqual(description, DESCRIPTION)
        self.assertLess(len(description), 1024)
        self.assertLessEqual(len(description.split(". ")[0].split()), 12)

    def test_headings_are_the_contract_in_order(self):
        self.assertEqual(helpers.headings(self.text), HEADINGS)

    def test_six_numbered_rules(self):
        rules = helpers.section(self.text, "Rules")
        self.assertEqual(re.findall(r"^(\d)\. \*\*", rules, re.M), ["1", "2", "3", "4", "5", "6"])
        for token in ["fix nothing", "is theirs", "never executed", "is data", "No trigger",
                      "judges no finding", "are not findings", "<REDACTED>"]:
            self.assertIn(token, rules)

    def test_every_reference_is_cited_and_every_citation_exists(self):
        folder = helpers.ROOT / helpers.SKILL / "references"
        self.assertEqual(sorted(path.name for path in folder.glob("*.md")), REFERENCES)
        cited = sorted(set(re.findall(r"references/([a-z-]+\.md)", self.text)))
        self.assertEqual(cited, REFERENCES)

    def test_target_sends_everything_but_the_uncommitted_work_to_its_reference(self):
        target = helpers.section(self.text, "1. Target")
        for token in ["dev-review-XXXXXX", "uncommitted work", "--untracked-files=all",
                      "`references/target.md`", "own", "foreign"]:
            self.assertIn(token, target)

    def test_context_names_its_four_parts(self):
        context = helpers.section(self.text, "2. Context")
        for token in ["intent.md", "claims.md", "<output>", "**Standards**", "**Baseline**",
                      "`.dev-runs/`"]:
            self.assertIn(token, context)

    def test_triage_holds_the_thresholds_the_depths_and_the_depth_line(self):
        triage = helpers.section(self.text, "3. Triage")
        for token in ["50", "1,000", "unless whoever asked named the lenses",
                      "Depth: <Small | Standard>[, self-run]", "quick", "thorough",
                      "correctness", "intent", "tests", "design", "**Self-run**",
                      "own change of 50 lines or fewer", "new surface",
                      "plan's task or slice", "*Without sub-agents*", "list of lenses"]:
            self.assertIn(token, triage)

    def test_checks_run_before_the_reviewers(self):
        checks = helpers.section(self.text, "4. Checks")
        for token in ["`references/checks.md`", "own change only", "every change", "not a finding"]:
            self.assertIn(token, checks)

    def test_review_tells_a_reviewer_nothing_to_ignore(self):
        self.assertIn("nothing to ignore", helpers.section(self.text, "5. Review"))

    def test_report_step_ends_the_answer_or_hands_it_back(self):
        report = helpers.section(self.text, "7. Report")
        for token in ["template's last line", "skill of the workflow", "fix nothing"]:
            self.assertIn(token, report)

    def test_without_sub_agents_marks_the_report(self):
        alone = helpers.section(self.text, "Without sub-agents")
        for token in ["self-run", "Run the checks", "weaker evidence"]:
            self.assertIn(token, alone)

    def test_no_tool_is_named(self):
        self.assertEqual(helpers.tool_names(self.text), [])


class Target(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = helpers.read(helpers.SKILL + "references/target.md")

    def test_headings_are_the_contract_in_order(self):
        self.assertEqual(
            helpers.headings(self.text),
            ["Contents", "What is reviewed", "Where the code is read", "Own or foreign"])

    def test_every_kind_of_target_is_resolved(self):
        what = helpers.section(self.text, "What is reviewed")
        for token in ["`git -C <repo> diff <merge base>`, with no head", "every untracked file",
                      "Its head is `HEAD`", "merge-base", "plan's slice", "`-- <paths>`",
                      "pull request",
                      "No git at all", "rev-parse --verify"]:
            self.assertIn(token, what)

    def test_the_users_repository_is_never_written(self):
        where = helpers.section(self.text, "Where the code is read")
        for token in ["includes the uncommitted work itself", "git clone -q --no-checkout",
                      "Never a checkout, a stash or a worktree"]:
            self.assertIn(token, where)

    def test_unsure_is_foreign(self):
        origin = helpers.section(self.text, "Own or foreign")
        for token in ["user.email", "Unsure is foreign", "this session built",
                      "a commit by another author"]:
            self.assertIn(token, origin)


if __name__ == "__main__":
    unittest.main()
