const List<String> migrationV3 = <String>[
  '''
  CREATE TABLE IF NOT EXISTS units_of_measure (
    id TEXT PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    unit_type TEXT NOT NULL
      CHECK(unit_type IN ('COUNT', 'WEIGHT', 'VOLUME', 'PACKAGING')),
    base_unit_code TEXT,
    conversion_factor REAL NOT NULL DEFAULT 1
      CHECK(conversion_factor > 0),
    allow_decimal INTEGER NOT NULL DEFAULT 0
      CHECK(allow_decimal IN (0, 1)),
    active INTEGER NOT NULL DEFAULT 1
      CHECK(active IN (0, 1)),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    sync_status TEXT NOT NULL DEFAULT 'PENDING'
      CHECK(sync_status IN ('PENDING', 'SYNCING', 'SYNCED', 'ERROR')),
    server_version INTEGER NOT NULL DEFAULT 0,
    deleted_at TEXT,
    CHECK(base_unit_code IS NULL OR base_unit_code != code)
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS unit_conversions (
    id TEXT PRIMARY KEY,
    source_unit_code TEXT NOT NULL,
    target_unit_code TEXT NOT NULL,
    conversion_factor REAL NOT NULL
      CHECK(conversion_factor > 0),
    conversion_scope TEXT NOT NULL DEFAULT 'UNIVERSAL'
      CHECK(conversion_scope IN ('UNIVERSAL', 'ITEM_SPECIFIC')),
    active INTEGER NOT NULL DEFAULT 1
      CHECK(active IN (0, 1)),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    sync_status TEXT NOT NULL DEFAULT 'PENDING'
      CHECK(sync_status IN ('PENDING', 'SYNCING', 'SYNCED', 'ERROR')),
    server_version INTEGER NOT NULL DEFAULT 0,
    UNIQUE(source_unit_code, target_unit_code, conversion_scope),
    CHECK(source_unit_code != target_unit_code),
    FOREIGN KEY(source_unit_code)
      REFERENCES units_of_measure(code),
    FOREIGN KEY(target_unit_code)
      REFERENCES units_of_measure(code)
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS product_packaging_conversions (
    id TEXT PRIMARY KEY,
    product_id TEXT NOT NULL,
    source_unit_code TEXT NOT NULL,
    target_unit_code TEXT NOT NULL,
    conversion_factor REAL NOT NULL
      CHECK(conversion_factor > 0),
    active INTEGER NOT NULL DEFAULT 1
      CHECK(active IN (0, 1)),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    sync_status TEXT NOT NULL DEFAULT 'PENDING'
      CHECK(sync_status IN ('PENDING', 'SYNCING', 'SYNCED', 'ERROR')),
    server_version INTEGER NOT NULL DEFAULT 0,
    UNIQUE(product_id, source_unit_code, target_unit_code),
    CHECK(source_unit_code != target_unit_code),
    FOREIGN KEY(product_id) REFERENCES products(id),
    FOREIGN KEY(source_unit_code)
      REFERENCES units_of_measure(code),
    FOREIGN KEY(target_unit_code)
      REFERENCES units_of_measure(code)
  )
  ''',
  '''
  ALTER TABLE suppliers
  ADD COLUMN contact_person TEXT
  ''',
  '''
  ALTER TABLE suppliers
  ADD COLUMN phone TEXT
  ''',
  '''
  ALTER TABLE suppliers
  ADD COLUMN email TEXT
  ''',
  '''
  ALTER TABLE suppliers
  ADD COLUMN address TEXT
  ''',
  '''
  ALTER TABLE suppliers
  ADD COLUMN tax_id TEXT
  ''',
  '''
  ALTER TABLE suppliers
  ADD COLUMN payment_terms TEXT
  ''',
  '''
  ALTER TABLE suppliers
  ADD COLUMN lead_time_days INTEGER NOT NULL DEFAULT 0
    CHECK(lead_time_days >= 0)
  ''',
  '''
  ALTER TABLE suppliers
  ADD COLUMN created_by TEXT
  ''',
  '''
  ALTER TABLE suppliers
  ADD COLUMN updated_by TEXT
  ''',
  '''
  ALTER TABLE suppliers
  ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'PENDING'
    CHECK(sync_status IN ('PENDING', 'SYNCING', 'SYNCED', 'ERROR'))
  ''',
  '''
  ALTER TABLE suppliers
  ADD COLUMN server_version INTEGER NOT NULL DEFAULT 0
  ''',
  '''
  ALTER TABLE suppliers
  ADD COLUMN deleted_at TEXT
  ''',
  '''
  CREATE INDEX IF NOT EXISTS idx_uom_code
  ON units_of_measure(code)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS idx_uom_type_active
  ON units_of_measure(unit_type, active)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS idx_unit_conversion_source
  ON unit_conversions(source_unit_code, active)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS idx_product_packaging_product
  ON product_packaging_conversions(product_id, active)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS idx_suppliers_code
  ON suppliers(supplier_code)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS idx_suppliers_name
  ON suppliers(supplier_name COLLATE NOCASE)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS idx_suppliers_active
  ON suppliers(active)
  '''
];
