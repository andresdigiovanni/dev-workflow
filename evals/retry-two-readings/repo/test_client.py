import unittest

from client import fetch


class FetchTest(unittest.TestCase):
    def test_returns_the_operation_result(self):
        self.assertEqual(fetch(lambda: 42), 42)

    def test_propagates_other_errors(self):
        def broken():
            raise ValueError("bad input")

        with self.assertRaises(ValueError):
            fetch(broken)


if __name__ == "__main__":
    unittest.main()
