import unittest

import review_helpers as helpers

PATH = helpers.SKILL + "references/reviewers.md"
LENSES = ["Correctness", "Intent", "Tests", "Design", "Security", "Operability"]
PLACEHOLDERS = ["<code>", "<repo>", "<diff command>", "<standards>", "<enforced>", "<output>"]
SHAPE = ["[<lens>] <title>", "Where:", "Trigger:", "Outcome:", "Missed:", "Fix:"]


class Reviewers(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = helpers.read(PATH)

    def brief(self, heading):
        blocks = helpers.fenced(helpers.section(self.text, heading))
        self.assertEqual(len(blocks), 1, f"{heading}: one code fence, found {len(blocks)}")
        return blocks[0]

    def test_headings_are_the_contract_in_order(self):
        self.assertEqual(helpers.headings(self.text), ["Contents", "Shared header", *LENSES])

    def test_contents_names_every_section(self):
        contents = helpers.section(self.text, "Contents")
        for name in ["Shared header", *LENSES]:
            self.assertIn(name, contents)

    def test_header_holds_the_placeholders_and_the_finding_shape(self):
        header = self.brief("Shared header")
        for token in PLACEHOLDERS + SHAPE:
            self.assertIn(token, header)

    def test_header_holds_the_two_lists_and_the_empty_result(self):
        header = self.brief("Shared header")
        for token in ["Cannot verify from the diff", "Declined to judge", "No findings"]:
            self.assertIn(token, header)

    def test_header_carries_the_rules_a_reviewer_needs(self):
        header = self.brief("Shared header").lower()
        for token in ["<redacted>", "sub-agent", "skill", "severity", "500 words", "instruction"]:
            self.assertIn(token, header)

    def test_header_carries_the_skip_list_and_the_unspecified_input(self):
        header = self.brief("Shared header")
        for token in ["Do not report these", "well-known constant", "missing doc", "exhaustive",
                      "formatter or linter owns", "nobody specified an input"]:
            self.assertIn(token, header)

    def test_diff_command_covers_a_branch_with_its_uncommitted_work(self):
        before = helpers.section(self.text, "Shared header").split("```")[0]
        self.assertIn("`git -C <repo> diff <merge base>`, with no head", before)

    def test_diff_command_covers_named_paths(self):
        before = helpers.section(self.text, "Shared header").split("```")[0]
        self.assertIn("the same command ending in `-- <paths>`", before)

    def test_placeholders_live_only_in_the_header(self):
        for lens in LENSES:
            for token in PLACEHOLDERS:
                self.assertNotIn(token, self.brief(lens), f"{token} in {lens}")

    def test_only_the_intent_lens_reads_the_claims(self):
        intent = self.brief("Intent")
        self.assertLess(intent.index("intent.md"), intent.index("claims.md"))
        for lens in LENSES:
            if lens != "Intent":
                self.assertNotIn("claims.md", self.brief(lens))
        self.assertNotIn("claims.md", self.brief("Shared header"))

    def test_intent_traces_hunks_surfaces_and_constraints(self):
        intent = self.brief("Intent")
        for token in ["Hunks that serve no requirement", "A surface the diff adds", "version floor"]:
            self.assertIn(token, intent)

    def test_tests_lens_names_every_way_a_test_or_a_check_is_bent(self):
        tests = self.brief("Tests")
        for token in ["skipped", "expected-to-fail", "focused", "loosened to get green"]:
            self.assertIn(token, tests)

    def test_security_separates_who_controls_the_value(self):
        security = self.brief("Security")
        self.assertIn("attacker-controlled", security)
        self.assertIn("server-controlled", security)

    def test_operability_names_its_triggers(self):
        operability = self.brief("Operability").lower()
        for token in ["rollback", "migration", "timeout", "lockfile", "default"]:
            self.assertIn(token, operability)

    def test_no_reviewer_is_asked_for_a_minimum(self):
        self.assertNotRegex(self.text.lower(), r"at least \w+ (finding|issue)s?")

    def test_briefs_wrap_and_no_tool_is_named(self):
        for block in helpers.fenced(self.text):
            for line in block.splitlines():
                self.assertLessEqual(len(line), 100, line[:40])
        self.assertEqual(helpers.tool_names(self.text), [])


if __name__ == "__main__":
    unittest.main()
