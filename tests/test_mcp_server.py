import sys
import os
import json
import pytest

# Adjust sys.path to allow importing from sku-db
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'sku-db')))

# Handle TDD missing module gracefully so test fails rather than errors out immediately on import
try:
    from server import search_products, get_product_by_sku, query_products_by_price
except ImportError:
    search_products = None
    get_product_by_sku = None
    query_products_by_price = None


def require_tools():
    if not all([search_products, get_product_by_sku, query_products_by_price]):
        pytest.fail("Tools not implemented yet in sku-db/server.py")


def test_search_products():
    require_tools()
    
    # Test match
    result = search_products("Apple")
    data = json.loads(result)
    assert isinstance(data, list)
    assert len(data) >= 1
    
    for item in data:
        name = item.get("name", "").lower()
        desc = item.get("description", "").lower()
        assert "apple" in name or "apple" in desc

    # Test no match
    result_empty = search_products("nonexistent_random_string")
    data_empty = json.loads(result_empty)
    assert isinstance(data_empty, list)
    assert len(data_empty) == 0


def test_get_product_by_sku():
    require_tools()
    
    # Test existing SKU
    # From seed.py, 4000 should be "Organic Apple"
    result = get_product_by_sku(4000)
    
    # The spec allows returning "a clear 'not found' response or null result rather than crashing"
    # Wait, the spec says "returns the correct structured record for that SKU" for existing
    assert result is not None
    data = json.loads(result)
    
    # In case the implementation returns a list of one item or a direct dict
    if isinstance(data, list):
        assert len(data) == 1
        item = data[0]
    else:
        item = data
        
    assert item.get("sku") == 4000
    assert "Apple" in item.get("name", "")

    # Test non-existent SKU
    result_none = get_product_by_sku(999999)
    if result_none is None or result_none.strip() == "":
        pass # Valid
    else:
        data_none = json.loads(result_none)
        if isinstance(data_none, list):
            assert len(data_none) == 0
        elif isinstance(data_none, dict):
            assert not data_none


def test_query_products_by_price():
    require_tools()
    
    # Test exact match (e.g. 0.99 for sku 4000)
    result = query_products_by_price(min_price=0.99, max_price=0.99)
    data = json.loads(result)
    assert isinstance(data, list)
    assert len(data) > 0
    for item in data:
        assert float(item.get("price")) == 0.99

    # Test range
    result_range = query_products_by_price(min_price=1.00, max_price=2.00)
    data_range = json.loads(result_range)
    assert isinstance(data_range, list)
    assert len(data_range) > 0
    for item in data_range:
        price = float(item.get("price"))
        assert 1.00 <= price <= 2.00

    # Test min only
    result_min = query_products_by_price(min_price=2.00)
    data_min = json.loads(result_min)
    assert isinstance(data_min, list)
    assert len(data_min) > 0
    for item in data_min:
        price = float(item.get("price"))
        assert price >= 2.00

    # Test max only
    result_max = query_products_by_price(max_price=1.50)
    data_max = json.loads(result_max)
    assert isinstance(data_max, list)
    assert len(data_max) > 0
    for item in data_max:
        price = float(item.get("price"))
        assert price <= 1.50
