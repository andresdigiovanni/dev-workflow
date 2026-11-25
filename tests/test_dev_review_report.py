import unittest

import review_helpers as helpers

PATH = helpers.SKILL + "references/report.md"
LABELS = [
    "Verdict: <Ready | Fix first: <numbers and failing checks> | Not settled: <what is open>>",
    "Does what was asked: <yes | no: <numbers> | not checked: <why>>",
    "Built right: <yes | no: <numbers> | not checked: <why>>",
    "Change:", "Target: <repo> <range> — <n> files, <n> changed lines",
    "Depth: <Small | Standard>[, self-run]",
    "── Checks ──",
    "Suite: <command> → <result; pre-existing reds named> | not run: <why>",
    "Types/lint/build: <command> → <result> | none configured | not run: <why>",
    "Entry point: <command> → <what it showed> | n/a | not run: <why>",
    "Agent file: <no update | update: <path>:<line> → <what is true now> | "
    "proposed: <instruction — evidence — gain>>",
    "── Findings ──",
    "Critical", "[<lens or lenses>; <reproduced | traced>]", "Trigger: <...>", "Outcome: <...>",
    "Fix: <...>", "Important", "Minor",
    "── Unsettled ──",
    "Needs checking:", "Pre-existing:", "Refuted:", "Not checked:",
]


class Report(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = helpers.read(PATH)

    def test_headings_are_the_contract_in_order(self):
        self.assertEqual(helpers.headings(self.text), ["Contents", "The template", "Filling it"])

    def test_template_holds_every_label_in_order(self):
        blocks = helpers.fenced(helpers.section(self.text, "The template"))
        self.assertEqual(len(blocks), 1, f"The template: one code fence, found {len(blocks)}")
        position = -1
        for label in LABELS:
            found = blocks[0].find(label, position + 1)
            self.assertGreater(found, position, f"{label} missing or out of order")
            position = found

    def test_filling_rules(self):
        filling = helpers.section(self.text, "Filling it")
        for token in [
                "No findings", "user's language", "reads `nothing`", "never blended",
                "no intent found", "<REDACTED>", "`[intent]`", "`[claims]`",
                "`ORIGIN: pre-existing`", "`Not settled`", "`Not checked` always stays",
                "with no number", "when a lens failed", "lens that did not run, with why",
                "never reads `yes`", "`Cannot verify from the diff`", "`Declined to judge`",
                "from the reviewer's", "from the verifier's", "each line one of its lenses",
                "nothing before the opening fence", "verified by nobody", "tests left out",
                "ends at the template's last line",
                "that skill continues after the report", "`not run: foreign`",
                "`references/checks.md`, *What a result does*",
                "a command could not run on an own change",
                "`<base>..<head> + uncommitted`", "`paths: <list>`",
                "one `text` code block", "one entry per line", "indented two spaces",
                "`── Checks ──`, `── Findings ──` and `── Unsettled ──` always stay",
                "`No findings` under `── Findings ──`"]:
            self.assertIn(token, filling)

    def test_the_suite_has_its_own_line_and_no_note(self):
        self.assertNotIn("the project's suite was not run", self.text)

    def test_no_tool_is_named(self):
        self.assertEqual(helpers.tool_names(self.text), [])


if __name__ == "__main__":
    unittest.main()
