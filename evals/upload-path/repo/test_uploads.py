import unittest

from uploads import list_uploads


class ListUploadsTest(unittest.TestCase):
    def test_lists_the_files_in_the_uploads_directory(self):
        self.assertEqual(list_uploads(), ["hello.txt"])


if __name__ == "__main__":
    unittest.main()
