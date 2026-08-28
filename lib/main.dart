import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kitchen_sync/app/app.dart';
import 'package:kitchen_sync/data/local/database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await AppDatabase.instance.database;
  runApp(const ProviderScope(child: KitchenSyncApp()));
}
