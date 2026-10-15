import unittest

from price import discounted


class DiscountedTest(unittest.TestCase):
    def test_applies_the_store_discount(self):
        self.assertEqual(discounted(100), 90.0)

    def test_zero_stays_zero(self):
        self.assertEqual(discounted(0), 0)


if __name__ == "__main__":
    unittest.main()
