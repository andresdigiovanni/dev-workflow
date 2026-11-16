import unittest

import review_helpers as helpers

PATH = helpers.SKILL + "references/verifier.md"
PLACEHOLDERS = ["<code>", "<repo>", "<diff command>", "<origin>", "<output>", "<findings>"]
ANSWER = [
    "FINDING:",
    "VERDICT: Confirmed | Refuted | Unproven",
    "EVIDENCE:",
    "ORIGIN: introduced | pre-existing",
    "SEVERITY: Critical | Important | Minor",
]


class Verifier(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = helpers.read(PATH)

    def brief(self):
        blocks = helpers.fenced(helpers.section(self.text, "The brief"))
        self.assertEqual(len(blocks), 1, f"The brief: one code fence, found {len(blocks)}")
        return blocks[0]

    def test_headings_are_the_contract_in_order(self):
        self.assertEqual(
            helpers.headings(self.text),
            ["Contents", "The brief", "Severity", "What to do with the answers"])

    def test_brief_holds_the_placeholders_and_the_answer_format(self):
        for token in PLACEHOLDERS + ANSWER:
            self.assertIn(token, self.brief())

    def test_brief_names_both_kinds_of_evidence_and_both_origins_of_the_change(self):
        brief = self.brief()
        for token in ["Confirmed needs", "reproduced or traced", "change is own, you may also run",
                      "change is foreign, run nothing else"]:
            self.assertIn(token, brief)

    def test_brief_grades_an_unspecified_input_by_what_the_caller_gets(self):
        self.assertIn("input nobody specified", self.brief())

    def test_coordinator_is_told_to_withhold_the_reviewers_reasoning(self):
        before = helpers.section(self.text, "The brief").split("```")[0]
        self.assertIn("`Missed`", before)
        self.assertIn("`Fix`", before)

    def test_severity_has_the_three_grades(self):
        severity = helpers.section(self.text, "Severity")
        for grade in ["**Critical**", "**Important**", "**Minor**"]:
            self.assertIn(grade, severity)

    def test_every_verdict_has_a_destination(self):
        answers = helpers.section(self.text, "What to do with the answers")
        for token in ["`Confirmed`: the finding stands", "`Refuted`: dropped",
                      "`Unproven`: under `Needs checking`"]:
            self.assertIn(token, answers)

    def test_brief_wraps_and_no_tool_is_named(self):
        for line in self.brief().splitlines():
            self.assertLessEqual(len(line), 100, line[:40])
        self.assertEqual(helpers.tool_names(self.text), [])


if __name__ == "__main__":
    unittest.main()
