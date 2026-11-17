"""What the rest of the set says about dev-review: the lane's path, where its findings are fixed,
and that nothing still names the skill it replaced."""
import unittest

import review_helpers as helpers


class Router(unittest.TestCase):
    def test_three_lanes_end_in_review_then_ship(self):
        router = helpers.read("router.md")
        self.assertEqual(router.count("`dev-implement` → `dev-review` → `dev-ship`"), 3)
        self.assertIn("`dev-review` reads them there", router)


class Implement(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = helpers.read("skills/dev-implement/SKILL.md")

    def test_after_the_review_sits_before_the_ledger(self):
        headings = helpers.headings(self.text)
        self.assertIn("After the review", headings)
        self.assertEqual(headings.index("After the review") + 1, headings.index("The ledger"))

    def test_after_the_review_says_what_is_fixed_and_how_it_ends(self):
        after = helpers.section(self.text, "After the review")
        for token in [
                "changes nothing", "`Critical` and `Important`", "test first", "`Trigger`",
                "`Agent file`", "`Minor` and `Pre-existing`", "`Needs checking` and `Not checked`",
                "a lens that failed or a group of files not covered",
                "had nothing to check needs nothing", "in direct mode",
                "run `dev-review` again, over the paths the fixes touched",
                "`dev-review`, *Checks*", "its report replaces the first",
                "Two reviews at most", "Decisions:", "Follow-ups:", "Open:",
                "`references/delegated.md`, *Per task* and *After the last task*"]:
            self.assertIn(token, after)
        for token in ["Fixed:", "Checks now:", "changed more than its finding named"]:
            self.assertNotIn(token, after)

    def test_the_last_task_waits_for_the_review(self):
        self.assertIn("waits for `dev-review`, run over the whole branch", self.text)
        self.assertIn("the requirement `dev-review` traces them to", self.text)

class Delegated(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = helpers.read("skills/dev-implement/references/delegated.md")

    def test_a_task_is_reviewed_at_small_depth(self):
        task = helpers.section(self.text, "Per task")
        for token in [
                "**3. Review the task** with `dev-review`, at Small depth", "`task-N-diff.md` first",
                "`task-N-brief.md` is the review's intent", "`task-N-report.md` its claims",
                "`dev-implement`, *After the review*", "a fresh `dev-review` at Small depth",
                "an `update` on the `Agent file` line"]:
            self.assertIn(token, task)

    def test_setup_describes_the_steps_as_they_are(self):
        setup = helpers.section(self.text, "Setup")
        for token in ["as they were reviewed: resuming compares the tree with it",
                      "`review` — settle it first"]:
            self.assertIn(token, setup)

    def test_a_slice_is_reviewed_and_the_branch_gets_the_intent_lens(self):
        slices = helpers.section(self.text, "Slices")
        for token in ["run `dev-review` on that slice", "its intent lens alone",
                      "the pre-PR `dev-review`"]:
            self.assertIn(token, slices)

    def test_a_fix_is_dispatched(self):
        self.assertIn(
            "A fix for what `dev-review` reports is not yours to write",
            helpers.section(self.text, "After the last task"))


class Ship(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = helpers.read("skills/dev-ship/SKILL.md")

    def test_the_trivial_lane_borrows_one_section(self):
        self.assertIn(
            "`dev-review`'s `references/checks.md`, *Instruction files*, and nothing else",
            helpers.section(self.text, "Trivial lane"))

    def test_integration_waits_for_the_verdict(self):
        self.assertIn(
            "the last `dev-review` reads `Ready`, or everything it left is settled or under `Open`",
            helpers.section(self.text, "Integrating"))

    def test_the_last_tasks_review_is_dev_review(self):
        self.assertIn(
            "the last task's review is `dev-review`",
            helpers.section(self.text, "One task, one commit"))

    def test_a_merge_runs_the_checks_and_the_intent_lens_again(self):
        self.assertIn("`dev-review`, *Checks*", helpers.section(self.text, "Integrating"))
        self.assertIn(
            "its checks and its intent lens alone", helpers.section(self.text, "When the target moved"))


class Debug(unittest.TestCase):
    def test_the_lane_ends_in_review(self):
        self.assertIn(
            "ends in `dev-review` and `dev-ship`", helpers.read("skills/dev-debug/SKILL.md"))


class Evals(unittest.TestCase):
    def test_the_scenarios_cite_the_sections_that_replaced_the_gates(self):
        for name, clause in [
                ("bent-check", "`dev-review`'s `references/reviewers.md`, *Tests*"),
                ("change-pinned-value", "`dev-review`'s `references/reviewers.md`, *Tests*"),
                ("upload-path", "`dev-review`, *Triage*"),
                ("upload-path", "`dev-implement`, *After the review*")]:
            scenario = helpers.read(f"evals/{name}/scenario.md")
            tests = [line for line in scenario.splitlines() if line.startswith("Tests:")]
            self.assertEqual(len(tests), 1, name)
            self.assertIn(clause, tests[0], name)
            self.assertNotIn("Gate", scenario, name)
            self.assertNotIn("Tests changed", scenario, name)


class Readme(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = helpers.read("README.md")

    def test_it_describes_the_review(self):
        for token in ["dev-review/        checks", "`dev-review/references/`",
                      "or `dev-ship` on the Trivial lane", "also runs outside the workflow"]:
            self.assertIn(token, self.text)


class Retired(unittest.TestCase):
    def test_nothing_installed_or_documented_names_dev_verify(self):
        self.assertFalse((helpers.ROOT / "skills" / "dev-verify").exists())
        paths = [helpers.ROOT / name for name in ("router.md", "README.md", "AGENTS.md")]
        for folder in ("skills", "evals"):
            paths += sorted((helpers.ROOT / folder).rglob("*.md"))
        named = [str(path.relative_to(helpers.ROOT)) for path in paths
                 if "dev-verify" in path.read_text(encoding="utf-8")]
        self.assertEqual(named, [])


if __name__ == "__main__":
    unittest.main()
