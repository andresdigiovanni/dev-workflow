"""The builder check's brief fixes a shape, and the rule that decides whether the check ran reads it."""
import unittest

import review_helpers as helpers

PATH = "skills/dev-plan/references/builder-check.md"


class BuilderCheck(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = helpers.read(PATH)

    def test_the_sorting_rule_keys_on_what_the_brief_asks_for(self):
        brief = helpers.section(self.text, "The brief")
        sorting = helpers.section(self.text, "Sorting what comes back")
        for token in ["`Paraphrase:`", "`Questions:`", "nothing important left"]:
            self.assertIn(token, brief)
            self.assertIn(token, sorting)
        self.assertIn("<n>. <question>", brief)
        self.assertIn("numbered questions", sorting)


if __name__ == "__main__":
    unittest.main()
