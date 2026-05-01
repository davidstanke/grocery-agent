import os
import sqlite3
import pytest

DB_PATH = 'sku-db/products.db'

def test_database_file_exists():
    assert os.path.exists(DB_PATH), f"Database file {DB_PATH} does not exist."

@pytest.fixture
def db_connection():
    # Only try to connect if the file exists to avoid creating an empty one by accident during tests
    if not os.path.exists(DB_PATH):
        pytest.fail(f"Database file {DB_PATH} is missing.")
    
    # Use URI=True and mode=ro to strictly read, though not strictly required
    conn = sqlite3.connect(DB_PATH)
    yield conn
    conn.close()

def test_skus_table_exists(db_connection):
    cursor = db_connection.cursor()
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='skus';")
    result = cursor.fetchone()
    assert result is not None, "Table 'skus' does not exist."

def test_skus_table_schema(db_connection):
    cursor = db_connection.cursor()
    cursor.execute("PRAGMA table_info(skus);")
    columns = cursor.fetchall()
    
    assert len(columns) > 0, "Table 'skus' has no columns."

    # columns format: (cid, name, type, notnull, dflt_value, pk)
    actual_columns = {col[1]: {'type': col[2].upper(), 'pk': col[5]} for col in columns}
    
    # Check sku
    assert 'sku' in actual_columns
    assert 'INT' in actual_columns['sku']['type'], "sku must be an INTEGER"
    assert actual_columns['sku']['pk'] >= 1, "sku must be PRIMARY KEY"

    # Check name
    assert 'name' in actual_columns
    assert 'VARCHAR' in actual_columns['name']['type'] or 'TEXT' in actual_columns['name']['type'], "name must be VARCHAR or TEXT"
    
    # Check price
    assert 'price' in actual_columns
    valid_price_types = ['REAL', 'DECIMAL', 'NUMERIC']
    assert any(pt in actual_columns['price']['type'] for pt in valid_price_types), "price must be REAL or DECIMAL"

    # Check description
    assert 'description' in actual_columns
    assert 'VARCHAR' in actual_columns['description']['type'] or 'TEXT' in actual_columns['description']['type'], "description must be VARCHAR or TEXT"
    
    assert len(actual_columns) == 4, f"Expected exactly 4 columns, found {len(actual_columns)}"

def test_skus_table_row_count(db_connection):
    cursor = db_connection.cursor()
    cursor.execute("SELECT COUNT(*) FROM skus;")
    count = cursor.fetchone()[0]
    assert 100 <= count <= 200, f"Expected 100-200 rows, found {count}."

def test_skus_values_are_4_digit_integers(db_connection):
    cursor = db_connection.cursor()
    cursor.execute("SELECT sku FROM skus;")
    skus = cursor.fetchall()
    
    assert len(skus) > 0, "No SKUs found to test."
    
    for (sku,) in skus:
        assert isinstance(sku, int), f"SKU {sku} is not an integer."
        assert 1000 <= sku <= 9999, f"SKU {sku} is not a 4-digit integer."
