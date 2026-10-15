DISCOUNT = 0.10


def discounted(amount):
    """Price after the store-wide discount, rounded to cents."""
    return round(amount * (1 - DISCOUNT), 2)
