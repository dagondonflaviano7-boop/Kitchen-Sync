const List<String> migrationV5 = <String>[
  '''
  CREATE TABLE IF NOT EXISTS recipe_master (
    id TEXT PRIMARY KEY,
    recipe_code TEXT NOT NULL UNIQUE,
    recipe_name TEXT NOT NULL,
    category TEXT NOT NULL
      CHECK(
        category IN (
          'mainDish',
          'sideDish',
          'beverage',
          'dessert',
          'sauce',
          'ingredientPrep'
        )
      ),
    yield_quantity REAL NOT NULL
      CHECK(yield_quantity > 0),
    yield_unit_code TEXT NOT NULL,
    active INTEGER NOT NULL DEFAULT 1
      CHECK(active IN (0, 1))
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS recipe_ingredients (
    id TEXT PRIMARY KEY,
    recipe_id TEXT NOT NULL,
    ingredient_id TEXT NOT NULL,
    ingredient_sku TEXT NOT NULL,
    ingredient_name TEXT NOT NULL,
    usage_unit_code TEXT NOT NULL,
    quantity_required REAL NOT NULL
      CHECK(quantity_required > 0),
    cost_per_usage_unit REAL NOT NULL
      CHECK(cost_per_usage_unit >= 0),
    UNIQUE(recipe_id, ingredient_id),
    FOREIGN KEY(recipe_id)
      REFERENCES recipe_master(id)
      ON DELETE CASCADE,
    FOREIGN KEY(ingredient_id)
      REFERENCES ingredients(id)
  )
  ''',
  '''
  CREATE INDEX IF NOT EXISTS
    idx_recipe_master_code
  ON recipe_master(recipe_code)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS
    idx_recipe_master_name
  ON recipe_master(
    recipe_name COLLATE NOCASE
  )
  ''',
  '''
  CREATE INDEX IF NOT EXISTS
    idx_recipe_master_category
  ON recipe_master(category)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS
    idx_recipe_master_active
  ON recipe_master(active)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS
    idx_recipe_ingredients_recipe
  ON recipe_ingredients(recipe_id)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS
    idx_recipe_ingredients_ingredient
  ON recipe_ingredients(ingredient_id)
  '''
];
