class Cache:
    """In-memory key-value store."""

    def __init__(self):
        self._items = {}

    def set(self, key, value):
        self._items[key] = value

    def get(self, key):
        """The stored value, or None when the key is missing."""
        return self._items.get(key)
