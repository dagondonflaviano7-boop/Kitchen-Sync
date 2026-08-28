import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final FirebaseAuth auth;
  final FirebaseDatabase database;
  FirebaseService({FirebaseAuth? auth, FirebaseDatabase? database})
      : auth = auth ?? FirebaseAuth.instance,
        database = database ?? FirebaseDatabase.instance;
  Future<UserCredential> signIn(String email, String password) =>
      auth.signInWithEmailAndPassword(email: email, password: password);
  Future<void> resetPassword(String email) =>
      auth.sendPasswordResetEmail(email: email);
  Future<void> signOut() => auth.signOut();
  Future<Map<String, dynamic>?> loadProfile(String uid) async {
    final snap = await database.ref('users/$uid').get();
    if (!snap.exists || snap.value is! Map) return null;
    return Map<String, dynamic>.from(snap.value as Map);
  }
}
