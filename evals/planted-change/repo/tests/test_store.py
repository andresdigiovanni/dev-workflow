import pathlib
import sqlite3
import unittest

from shop import store

MIGRATIONS = pathlib.Path(__file__).resolve().parent.parent / "migrations"


def database():
    conn = sqlite3.connect(":memory:")
    for path in sorted(MIGRATIONS.glob("*.sql")):
        conn.executescript(path.read_text())
    return conn


class Quantities(unittest.TestCase):
    def test_returns_what_was_ordered(self):
        conn = database()
        store.add_order(conn, "ana", 2)
        self.assertEqual(store.quantities(conn, "ana"), [2])
