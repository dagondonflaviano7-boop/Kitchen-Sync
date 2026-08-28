import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v1.dart';

void main() {
  test('critical phase 1 tables declared', () {
    final sql = migrationV1.join(' ');
    for (final table in [
      'products',
      'ingredients',
      'recipes',
      'inventory',
      'sales',
      'cashier_sessions',
      'costing',
      'sync_queue'
    ]) {
      expect(sql.contains('CREATE TABLE $table'), isTrue);
    }
  });
}
