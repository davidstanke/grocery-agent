import sqlite3
import os

def create_and_seed_db():
    db_path = 'sku-db/products.db'
    schema_path = 'sku-db/schema.sql'
    
    # Ensure the directory exists
    os.makedirs('sku-db', exist_ok=True)
    
    # Connect to db
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Execute schema
    with open(schema_path, 'r') as f:
        schema_sql = f.read()
    cursor.executescript(schema_sql)
    
    # Generate items
    items = []
    base_sku = 4000
    produce_types = [
        "Apple", "Banana", "Orange", "Lettuce", "Tomato", "Onion", "Garlic", 
        "Carrot", "Potato", "Cucumber", "Broccoli", "Cauliflower", "Spinach", 
        "Kale", "Mushroom", "Pepper", "Zucchini", "Squash", "Avocado", "Lemon", 
        "Lime", "Grapefruit", "Grapes", "Strawberry", "Blueberry", "Raspberry", 
        "Blackberry", "Watermelon", "Cantaloupe", "Honeydew", "Peach", "Plum", 
        "Nectarine", "Cherry", "Pear", "Mango", "Pineapple", "Papaya", "Kiwi"
    ]
    varieties = ["Organic", "Conventional", "Local", "Premium"]

    # generate combinations until we have 150 unique
    sku_counter = 4000
    for t in produce_types:
        for v in varieties:
            if len(items) >= 150:
                break
            name = f"{v} {t}"
            price = round(0.99 + (sku_counter % 5) * 0.50, 2)
            desc = f"Fresh {name.lower()} for your grocery needs."
            items.append((sku_counter, name, price, desc))
            sku_counter += 1
            
    cursor.executemany("INSERT INTO skus (sku, name, price, description) VALUES (?, ?, ?, ?)", items)
    conn.commit()
    conn.close()
    print(f"Seeded {len(items)} items into {db_path}.")

if __name__ == '__main__':
    create_and_seed_db()
