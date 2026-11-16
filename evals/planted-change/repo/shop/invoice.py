from shop.quantity import parse_quantity


def line_total(price_cents, quantity_text):
    """The total of one order line, in cents."""
    return price_cents * parse_quantity(quantity_text)
