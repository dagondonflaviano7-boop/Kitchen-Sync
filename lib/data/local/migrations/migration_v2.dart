const List<String> migrationV2 = <String>[
  '''
  CREATE TABLE IF NOT EXISTS store_user_assignments (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    store_id TEXT NOT NULL,
    is_default INTEGER NOT NULL DEFAULT 0,
    active INTEGER NOT NULL DEFAULT 1,
    sync_status TEXT NOT NULL DEFAULT 'SYNCED',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    UNIQUE(user_id, store_id),
    FOREIGN KEY(user_id) REFERENCES users(id),
    FOREIGN KEY(store_id) REFERENCES stores(id)
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS master_data_sync_state (
    entity_type TEXT NOT NULL,
    store_id TEXT NOT NULL,
    last_pulled_at TEXT,
    last_server_version INTEGER NOT NULL DEFAULT 0,
    last_error TEXT,
    updated_at TEXT NOT NULL,
    PRIMARY KEY(entity_type, store_id)
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS master_data_conflicts (
    id TEXT PRIMARY KEY,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    store_id TEXT NOT NULL,
    local_payload TEXT NOT NULL,
    remote_payload TEXT NOT NULL,
    local_version INTEGER NOT NULL DEFAULT 0,
    server_version INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'OPEN'
      CHECK(status IN ('OPEN', 'RESOLVED_LOCAL', 'RESOLVED_REMOTE', 'MERGED')),
    created_at TEXT NOT NULL,
    resolved_at TEXT,
    resolved_by TEXT
  )
  ''',
  '''
  CREATE INDEX IF NOT EXISTS idx_store_assignments_user
  ON store_user_assignments(user_id)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS idx_store_assignments_store
  ON store_user_assignments(store_id)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS idx_master_conflicts_entity
  ON master_data_conflicts(entity_type, entity_id)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS idx_master_conflicts_status
  ON master_data_conflicts(status, created_at)
  '''
];
