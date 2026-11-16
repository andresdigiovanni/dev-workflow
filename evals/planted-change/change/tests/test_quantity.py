import unittest
from unittest import mock

from shop.invoice import line_total


class EmptyQuantity(unittest.TestCase):
    def test_an_empty_quantity_totals_zero(self):
        with mock.patch("shop.invoice.parse_quantity", return_value=0):
            self.assertEqual(line_total(250, ""), 0)
