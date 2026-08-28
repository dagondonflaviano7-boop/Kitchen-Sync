import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kitchen_sync/data/repositories/local_session_repository.dart';
import 'package:kitchen_sync/data/repositories/remote_session_repository.dart';
import 'package:kitchen_sync/features/authentication/presentation/access_blocked_screen.dart';
import 'package:kitchen_sync/features/authentication/presentation/login_screen.dart';
import 'package:kitchen_sync/features/authentication/presentation/profile_loading_screen.dart';
import 'package:kitchen_sync/features/dashboard/presentation/adaptive_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ProfileLoadingScreen();
        }

        if (snapshot.hasError) {
          return AccessBlockedScreen(
            title: 'Session unavailable',
            message: 'Kitchen Sync could not verify the current login session.',
            statusLabel: 'Authentication unavailable',
            icon: Icons.cloud_off_outlined,
          );
        }

        final User? user = snapshot.data;

        if (user == null) {
          return const LoginScreen();
        }

        return AuthorizedUserGate(
          key: ValueKey<String>(user.uid),
          user: user,
        );
      },
    );
  }
}

class AuthorizedUserGate extends StatefulWidget {
  final User user;

  const AuthorizedUserGate({
    super.key,
    required this.user,
  });

  @override
  State<AuthorizedUserGate> createState() => _AuthorizedUserGateState();
}

class _AuthorizedUserGateState extends State<AuthorizedUserGate> {
  final RemoteSessionRepository _repository = RemoteSessionRepository();

  late Future<LocalSessionContext> _contextFuture;

  @override
  void initState() {
    super.initState();
    _contextFuture = _loadContext();
  }

  Future<LocalSessionContext> _loadContext() {
    return _repository.loadAndCacheContext(
      widget.user.uid,
    );
  }

  void _retry() {
    setState(() {
      _contextFuture = _loadContext();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LocalSessionContext>(
      future: _contextFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ProfileLoadingScreen();
        }

        if (snapshot.hasData) {
          return AdaptiveShell(
            sessionContext: snapshot.data!,
          );
        }

        final Object? error = snapshot.error;

        if (error is SessionAccessException) {
          return _buildAccessFailure(error);
        }

        return AccessBlockedScreen(
          title: 'Unable to verify access',
          message: 'Kitchen Sync encountered an unexpected problem while '
              'loading the user and store profile.',
          statusLabel: 'Profile verification failed',
          icon: Icons.error_outline,
          onRetry: _retry,
        );
      },
    );
  }

  Widget _buildAccessFailure(
    SessionAccessException exception,
  ) {
    return switch (exception.failure) {
      SessionAccessFailure.profileMissing => AccessBlockedScreen(
          title: 'Profile not configured',
          message: 'The signed-in Firebase account does not have a '
              'Kitchen Sync user profile.',
          statusLabel: 'User profile unavailable',
          icon: Icons.person_off_outlined,
          onRetry: _retry,
        ),
      SessionAccessFailure.profileInvalid => AccessBlockedScreen(
          title: 'Invalid user profile',
          message: 'The Kitchen Sync user profile is incomplete or '
              'contains an unsupported role.',
          statusLabel: 'Profile configuration invalid',
          icon: Icons.manage_accounts_outlined,
          onRetry: _retry,
        ),
      SessionAccessFailure.accountInactive => AccessBlockedScreen(
          title: 'Account inactive',
          message: 'This Kitchen Sync account is inactive. Contact a '
              'Kitchen Sync administrator to restore access.',
          statusLabel: 'Account access disabled',
          icon: Icons.no_accounts_outlined,
          onRetry: _retry,
        ),
      SessionAccessFailure.storeMissing => AccessBlockedScreen(
          title: 'Store not configured',
          message: 'The store assigned to this account could not be found.',
          statusLabel: 'Assigned store unavailable',
          icon: Icons.store_mall_directory_outlined,
          onRetry: _retry,
        ),
      SessionAccessFailure.storeInvalid => AccessBlockedScreen(
          title: 'Invalid store configuration',
          message: 'The assigned Kitchen Sync store record is incomplete '
              'or invalid.',
          statusLabel: 'Store configuration invalid',
          icon: Icons.storefront_outlined,
          onRetry: _retry,
        ),
      SessionAccessFailure.storeInactive => AccessBlockedScreen(
          title: 'Store inactive',
          message: 'The assigned Kitchen Sync store is currently inactive.',
          statusLabel: 'Store access disabled',
          icon: Icons.storefront_outlined,
          onRetry: _retry,
        ),
      SessionAccessFailure.networkUnavailable => AccessBlockedScreen(
          title: 'Access unavailable',
          message: 'Kitchen Sync could not verify this account online, '
              'and no previously validated offline profile was found.',
          statusLabel: 'Profile connection unavailable',
          icon: Icons.cloud_off_outlined,
          onRetry: _retry,
        ),
    };
  }
}
