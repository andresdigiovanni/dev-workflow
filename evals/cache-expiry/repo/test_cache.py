import unittest

from cache import Cache


class CacheTest(unittest.TestCase):
    def test_returns_what_was_set(self):
        cache = Cache()
        cache.set("a", 1)
        self.assertEqual(cache.get("a"), 1)

    def test_missing_key_is_none(self):
        self.assertIsNone(Cache().get("missing"))


if __name__ == "__main__":
    unittest.main()
