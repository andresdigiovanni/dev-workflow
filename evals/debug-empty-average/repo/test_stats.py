import unittest

from stats import average


class AverageTest(unittest.TestCase):
    def test_mean_of_several_values(self):
        self.assertEqual(average([1, 2, 3]), 2)


if __name__ == "__main__":
    unittest.main()
