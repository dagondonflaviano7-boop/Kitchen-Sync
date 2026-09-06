const List<String> migrationV10 = <String>[
  '''
  ALTER TABLE ingredient_movements
  ADD COLUMN recipe_id TEXT
  ''',
  '''
  ALTER TABLE ingredient_movements
  ADD COLUMN recipe_ingredient_id TEXT
  ''',
  '''
  CREATE INDEX IF NOT EXISTS
    idx_ingredient_movements_recipe
  ON ingredient_movements(recipe_id)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS
    idx_ingredient_movements_recipe_line
  ON ingredient_movements(recipe_ingredient_id)
  ''',
];
