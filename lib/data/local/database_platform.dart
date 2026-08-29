import 'package:kitchen_sync/data/local/database_platform_stub.dart'
    if (dart.library.js_interop) 'package:kitchen_sync/data/local/database_platform_web.dart';

void initializeDatabasePlatform() {
  initializeDatabasePlatformImplementation();
}
