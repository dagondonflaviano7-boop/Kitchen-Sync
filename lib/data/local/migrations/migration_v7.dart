const List<String> migrationV7 = <String>[
  '''
  ALTER TABLE products
  ADD COLUMN recipe_id TEXT
  ''',
  '''
  CREATE INDEX IF NOT EXISTS
    idx_products_recipe_id
  ON products(recipe_id)
  ''',
];
