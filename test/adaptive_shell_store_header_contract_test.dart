import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String shell;

  setUpAll(() {
    final File file = File(
      'lib/features/dashboard/presentation/'
      'adaptive_shell.dart',
    );

    expect(
      file.existsSync(),
      isTrue,
      reason: 'Adaptive Shell must exist.',
    );

    shell = file.readAsStringSync();
  });

  void containsAll(
    List<String> values,
  ) {
    for (final String value in values) {
      expect(
        shell,
        contains(value),
        reason: 'Expected Adaptive Shell to contain $value.',
      );
    }
  }

  group('tablet Store header alignment', () {
    test('places Store identity in tablet AppBar', () {
      containsAll(<String>[
        'title: tablet',
        "'KITCHEN SYNC'",
        'appBar: true',
        'titleSpacing: 16',
      ]);
    });

    test('supports compact AppBar Store identity', () {
      containsAll(<String>[
        'final bool appBar;',
        'this.appBar = false',
        'if (appBar)',
        'store.storeName',
        'store.storeCode',
      ]);
    });

    test('keeps compact identity in NavigationRail', () {
      containsAll(<String>[
        'NavigationRail(',
        'compact: true',
      ]);
    });

    test('renders selected page directly on tablet', () {
      containsAll(<String>[
        'Expanded(',
        'child: available[safeIndex].page',
      ]);
    });

    test('preserves mobile Store identity strip', () {
      containsAll(<String>[
        ': Column(',
        '_StoreIdentityCard(',
        'Expanded(',
      ]);
    });
  });
}
