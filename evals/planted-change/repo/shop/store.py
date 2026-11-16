TABLE = "orders"


def add_order(conn, customer, qty):
    conn.execute("INSERT INTO orders (customer, qty) VALUES (?, ?)", (customer, qty))


def quantities(conn, customer):
    rows = conn.execute("SELECT qty FROM orders WHERE customer = ?", (customer,))
    return [row[0] for row in rows]
