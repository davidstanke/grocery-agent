DROP TABLE IF EXISTS skus;

CREATE TABLE skus (
    sku INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    price REAL NOT NULL,
    description TEXT NOT NULL
);