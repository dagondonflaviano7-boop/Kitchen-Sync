import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_sync/app/app.dart';
import 'package:kitchen_sync/data/local/database.dart';
import 'package:kitchen_sync/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseDatabase.instance.setPersistenceEnabled(true);
  FirebaseDatabase.instance.setPersistenceCacheSizeBytes(
    20 * 1024 * 1024,
  );

  await AppDatabase.instance.database;

  runApp(
    const ProviderScope(
      child: KitchenSyncApp(),
    ),
  );
}
