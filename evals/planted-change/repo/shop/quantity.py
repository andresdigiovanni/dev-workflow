def parse_quantity(text):
    """The quantity typed on an order line. Raises ValueError when it is not a whole number."""
    return int(text.strip())
