import 'package:flutter/material.dart';
import 'package:kitchen_sync/app/theme.dart';
import 'package:kitchen_sync/features/authentication/presentation/auth_gate.dart';

class KitchenSyncApp extends StatelessWidget {
  const KitchenSyncApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'Kitchen Sync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate());
}
