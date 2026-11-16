import unittest

import review_helpers as helpers

PATH = helpers.SKILL + "references/checks.md"


class Checks(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = helpers.read(PATH)

    def test_headings_are_the_contract_in_order(self):
        self.assertEqual(
            helpers.headings(self.text),
            ["Contents", "The commands", "Instruction files", "What a result does"])

    def test_commands_run_on_an_own_change_only(self):
        commands = helpers.section(self.text, "The commands")
        for token in ["On an own change only", "`not run: foreign`", "**full** test suite",
                      "type checker", "check mode", "the build", "entry point", "`n/a`",
                      "exact command", "exit code", "`none configured`", "pre-existing",
                      "Install nothing"]:
            self.assertIn(token, commands)

    def test_instruction_files_is_a_search_with_three_outcomes(self):
        files = helpers.section(self.text, "Instruction files")
        for token in ["never an edit", "**Changed names**", "**New operational facts**",
                      "`no update`", "`update: <path>:<line> → <what is true now>`",
                      "`proposed: <instruction — evidence — gain>`"]:
            self.assertIn(token, files)

    def test_a_result_reaches_the_verdict(self):
        result = helpers.section(self.text, "What a result does")
        for token in ["`Fix first`", "the baseline did not show failing", "`agent file`",
                      "`Not settled`", "change no verdict"]:
            self.assertIn(token, result)

    def test_no_tool_is_named(self):
        self.assertEqual(helpers.tool_names(self.text), [])


if __name__ == "__main__":
    unittest.main()
