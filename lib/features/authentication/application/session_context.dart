import 'package:kitchen_sync/data/repositories/local_session_repository.dart';

enum SessionContextStatus {
  loading,
  authorized,
  profileMissing,
  profileInvalid,
  accountInactive,
  storeMissing,
  storeInvalid,
  storeInactive,
  unavailable,
}

class SessionContextState {
  final SessionContextStatus status;
  final LocalSessionContext? context;
  final String? message;

  const SessionContextState({
    required this.status,
    this.context,
    this.message,
  });

  const SessionContextState.loading()
      : status = SessionContextStatus.loading,
        context = null,
        message = null;

  const SessionContextState.authorized(
    LocalSessionContext value,
  )   : status = SessionContextStatus.authorized,
        context = value,
        message = null;

  const SessionContextState.blocked({
    required this.status,
    required this.message,
  }) : context = null;

  bool get isAuthorized {
    return status == SessionContextStatus.authorized && context != null;
  }
}
