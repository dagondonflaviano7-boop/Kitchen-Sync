const List<String> migrationV8 = <String>[
  '''
  ALTER TABLE products
  ADD COLUMN sync_status TEXT NOT NULL
    DEFAULT 'PENDING'
    CHECK(
      sync_status IN (
        'PENDING',
        'SYNCING',
        'SYNCED',
        'ERROR'
      )
    )
  ''',
  '''
  ALTER TABLE products
  ADD COLUMN server_version INTEGER NOT NULL
    DEFAULT 0
    CHECK(server_version >= 0)
  ''',
  '''
  ALTER TABLE products
  ADD COLUMN deleted_at TEXT
  ''',
  '''
  CREATE INDEX IF NOT EXISTS
    idx_products_sync
  ON products(sync_status)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS
    idx_products_active_deleted
  ON products(active, deleted_at)
  ''',
];
