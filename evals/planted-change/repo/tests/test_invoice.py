import unittest

from shop.invoice import line_total


class LineTotal(unittest.TestCase):
    def test_multiplies_price_by_quantity(self):
        self.assertEqual(line_total(250, " 3 "), 750)

    def test_rejects_a_quantity_that_is_not_a_number(self):
        with self.assertRaises(ValueError):
            line_total(250, "three")
