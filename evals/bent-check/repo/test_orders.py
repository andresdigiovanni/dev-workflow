import unittest

from orders import order_total


class OrderTotalTest(unittest.TestCase):
    def test_sums_price_times_quantity(self):
        self.assertEqual(order_total([(2.5, 2), (1, 3)]), 8.0)


if __name__ == "__main__":
    unittest.main()
