def order_total(items):
    """Sum of price * quantity over (price, quantity) pairs."""
    total = sum(price * quantity for price, quantity in items)
    print("DEBUG total", total)
    return total
