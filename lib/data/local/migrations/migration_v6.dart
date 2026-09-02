const List<String> migrationV6 = <String>[
  '''
  ALTER TABLE recipe_master
  ADD COLUMN created_at TEXT NOT NULL
    DEFAULT '1970-01-01T00:00:00.000Z'
  ''',
  '''
  ALTER TABLE recipe_master
  ADD COLUMN updated_at TEXT NOT NULL
    DEFAULT '1970-01-01T00:00:00.000Z'
  ''',
  '''
  ALTER TABLE recipe_master
  ADD COLUMN created_by TEXT
  ''',
  '''
  ALTER TABLE recipe_master
  ADD COLUMN updated_by TEXT
  ''',
  '''
  ALTER TABLE recipe_master
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
  ALTER TABLE recipe_master
  ADD COLUMN server_version INTEGER NOT NULL
    DEFAULT 0
    CHECK(server_version >= 0)
  ''',
  '''
  ALTER TABLE recipe_master
  ADD COLUMN deleted_at TEXT
  ''',
  '''
  CREATE INDEX IF NOT EXISTS
    idx_recipe_master_sync
  ON recipe_master(sync_status)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS
    idx_recipe_master_active_deleted
  ON recipe_master(active, deleted_at)
  '''
];
