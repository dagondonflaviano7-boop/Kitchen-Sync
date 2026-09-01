const List<String> migrationV4 = <String>[
  '''
  ALTER TABLE ingredients
  ADD COLUMN notes TEXT
  ''',
  '''
  ALTER TABLE ingredients
  ADD COLUMN image_path TEXT
  ''',
  '''
  ALTER TABLE ingredients
  ADD COLUMN created_by TEXT
  ''',
  '''
  ALTER TABLE ingredients
  ADD COLUMN updated_by TEXT
  ''',
  '''
  ALTER TABLE ingredients
  ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'PENDING'
    CHECK(sync_status IN ('PENDING', 'SYNCING', 'SYNCED', 'ERROR'))
  ''',
  '''
  ALTER TABLE ingredients
  ADD COLUMN server_version INTEGER NOT NULL DEFAULT 0
  ''',
  '''
  ALTER TABLE ingredients
  ADD COLUMN deleted_at TEXT
  ''',
  '''
  CREATE INDEX IF NOT EXISTS idx_ingredients_name
  ON ingredients(ingredient_name COLLATE NOCASE)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS idx_ingredients_category
  ON ingredients(category)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS idx_ingredients_supplier
  ON ingredients(supplier_id)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS idx_ingredients_sync
  ON ingredients(sync_status)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS idx_ingredients_active_deleted
  ON ingredients(active, deleted_at)
  '''
];
