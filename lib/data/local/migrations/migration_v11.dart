const List<String> migrationV11 = <String>[
  '''
  CREATE TABLE sale_restorations (
    id TEXT PRIMARY KEY,
    restoration_transaction_number TEXT NOT NULL UNIQUE,
    original_sale_id TEXT NOT NULL,
    operation TEXT NOT NULL
      CHECK(operation IN ('VOID', 'REFUND')),
    reason TEXT NOT NULL,
    subtotal REAL NOT NULL
      CHECK(subtotal <= 0),
    discount REAL NOT NULL
      CHECK(discount <= 0),
    net_sales REAL NOT NULL
      CHECK(net_sales <= 0),
    cost REAL NOT NULL
      CHECK(cost <= 0),
    cogs REAL NOT NULL
      CHECK(cogs <= 0),
    gross_profit REAL NOT NULL,
    gross_margin REAL NOT NULL,
    performed_by TEXT NOT NULL,
    device_id TEXT NOT NULL,
    occurred_at TEXT NOT NULL,
    sync_status TEXT NOT NULL DEFAULT 'PENDING',
    FOREIGN KEY(original_sale_id) REFERENCES sales(id)
  )
  ''',
  '''
  CREATE TABLE sale_restoration_items (
    id TEXT PRIMARY KEY,
    restoration_id TEXT NOT NULL,
    original_sale_item_id TEXT NOT NULL,
    product_id TEXT NOT NULL,
    sku TEXT NOT NULL,
    product_name TEXT NOT NULL,
    quantity REAL NOT NULL
      CHECK(quantity > 0),
    selling_price REAL NOT NULL
      CHECK(selling_price >= 0),
    discount REAL NOT NULL
      CHECK(discount >= 0),
    net_amount REAL NOT NULL
      CHECK(net_amount >= 0),
    unit_cost REAL NOT NULL
      CHECK(unit_cost >= 0),
    cogs REAL NOT NULL
      CHECK(cogs >= 0),
    recipe_version INTEGER
      CHECK(recipe_version IS NULL OR recipe_version > 0),
    ingredient_cost_json TEXT,
    FOREIGN KEY(restoration_id)
      REFERENCES sale_restorations(id),
    FOREIGN KEY(original_sale_item_id)
      REFERENCES sale_items(id)
  )
  ''',
  '''
  ALTER TABLE inventory_movements
  ADD COLUMN source_restoration_id TEXT
  ''',
  '''
  ALTER TABLE ingredient_movements
  ADD COLUMN source_restoration_id TEXT
  ''',
  '''
  CREATE INDEX IF NOT EXISTS
    idx_sale_restorations_original_sale
  ON sale_restorations(original_sale_id)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS
    idx_sale_restorations_sync
  ON sale_restorations(sync_status)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS
    idx_sale_restoration_items_restoration
  ON sale_restoration_items(restoration_id)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS
    idx_sale_restoration_items_original_item
  ON sale_restoration_items(original_sale_item_id)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS
    idx_inventory_movements_restoration
  ON inventory_movements(source_restoration_id)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS
    idx_ingredient_movements_restoration
  ON ingredient_movements(source_restoration_id)
  ''',
  '''
  CREATE UNIQUE INDEX IF NOT EXISTS
    idx_inventory_movements_one_reversal
  ON inventory_movements(reversal_of_movement_id)
  WHERE reversal_of_movement_id IS NOT NULL
  ''',
  '''
  CREATE UNIQUE INDEX IF NOT EXISTS
    idx_ingredient_movements_one_reversal
  ON ingredient_movements(reversal_of_movement_id)
  WHERE reversal_of_movement_id IS NOT NULL
  ''',
];
