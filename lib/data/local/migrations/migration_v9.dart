const List<String> migrationV9 = <String>[
  '''
  ALTER TABLE inventory_movements
  ADD COLUMN idempotency_key TEXT
  ''',
  '''
  ALTER TABLE inventory_movements
  ADD COLUMN source_sale_id TEXT
  ''',
  '''
  ALTER TABLE inventory_movements
  ADD COLUMN source_sale_item_id TEXT
  ''',
  '''
  ALTER TABLE inventory_movements
  ADD COLUMN reversal_of_movement_id TEXT
  ''',
  '''
  ALTER TABLE inventory_movements
  ADD COLUMN unit_cost_snapshot REAL NOT NULL
    DEFAULT 0
    CHECK(unit_cost_snapshot >= 0)
  ''',
  '''
  ALTER TABLE ingredient_movements
  ADD COLUMN idempotency_key TEXT
  ''',
  '''
  ALTER TABLE ingredient_movements
  ADD COLUMN source_sale_id TEXT
  ''',
  '''
  ALTER TABLE ingredient_movements
  ADD COLUMN source_sale_item_id TEXT
  ''',
  '''
  ALTER TABLE ingredient_movements
  ADD COLUMN reversal_of_movement_id TEXT
  ''',
  '''
  ALTER TABLE ingredient_movements
  ADD COLUMN unit_cost_snapshot REAL NOT NULL
    DEFAULT 0
    CHECK(unit_cost_snapshot >= 0)
  ''',
  '''
  CREATE UNIQUE INDEX IF NOT EXISTS
    idx_inventory_movements_idempotency
  ON inventory_movements(idempotency_key)
  WHERE idempotency_key IS NOT NULL
  ''',
  '''
  CREATE UNIQUE INDEX IF NOT EXISTS
    idx_ingredient_movements_idempotency
  ON ingredient_movements(idempotency_key)
  WHERE idempotency_key IS NOT NULL
  ''',
  '''
  CREATE INDEX IF NOT EXISTS
    idx_inventory_movements_reversal
  ON inventory_movements(reversal_of_movement_id)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS
    idx_ingredient_movements_reversal
  ON ingredient_movements(reversal_of_movement_id)
  ''',
];
