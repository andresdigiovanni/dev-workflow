TABLE = "orders"


def add_order(conn, customer, quantity):
    conn.execute("INSERT INTO orders (customer, quantity) VALUES (?, ?)", (customer, quantity))


def quantities(conn, customer):
    rows = conn.execute("SELECT quantity FROM orders WHERE customer = ?", (customer,))
    return [row[0] for row in rows]


def count_orders(conn):
    return conn.execute(f"SELECT COUNT(*) FROM {TABLE}").fetchone()[0]
