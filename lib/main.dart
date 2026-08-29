import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_sync/app/app.dart';
import 'package:kitchen_sync/data/local/database.dart';
import 'package:kitchen_sync/data/local/database_platform.dart';
import 'package:kitchen_sync/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  initializeDatabasePlatform();

  runApp(
    const ProviderScope(
      child: KitchenSyncBootstrap(),
    ),
  );
}

class KitchenSyncBootstrap extends StatefulWidget {
  const KitchenSyncBootstrap({super.key});

  @override
  State<KitchenSyncBootstrap> createState() => _KitchenSyncBootstrapState();
}

class _KitchenSyncBootstrapState extends State<KitchenSyncBootstrap> {
  late Future<void> _startupFuture;

  @override
  void initState() {
    super.initState();
    _startupFuture = _initializeApplication();
  }

  Future<void> _initializeApplication() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (!kIsWeb) {
      FirebaseDatabase.instance.setPersistenceCacheSizeBytes(
        20 * 1024 * 1024,
      );

      FirebaseDatabase.instance.setPersistenceEnabled(true);
    }

    await AppDatabase.instance.database;
  }

  void _retry() {
    setState(() {
      _startupFuture = _initializeApplication();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kitchen Sync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E6B4F),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
      ),
      home: FutureBuilder<void>(
        future: _startupFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _StartupLoadingScreen();
          }

          if (snapshot.hasError) {
            return _StartupErrorScreen(
              error: snapshot.error,
              onRetry: _retry,
            );
          }

          return const KitchenSyncApp();
        },
      ),
    );
  }
}

class _StartupLoadingScreen extends StatelessWidget {
  const _StartupLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.restaurant_menu,
                  size: 80,
                  color: Color(0xFF2E6B4F),
                ),
                SizedBox(height: 20),
                Text(
                  'KITCHEN SYNC',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Preparing secure local data...',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const _StartupErrorScreen({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final String message = error?.toString() ?? 'Unknown startup error';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Sync'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 520,
              ),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Kitchen Sync could not start',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'The application encountered an initialization '
                        'problem. No sales or inventory data was created.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SelectableText(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
