import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class UserProfileRepository {
  Future<void> upsertProfile(User user);
  Future<String?> findUidByEmail(String email);
}

class FirestoreUserProfileRepository implements UserProfileRepository {
  FirestoreUserProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> upsertProfile(User user) async {
    final email = user.email?.toLowerCase();
    if (email == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'email': email,
        'displayName': user.displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!_isValidKey(email)) return;

      var verified = user.emailVerified;
      if (!verified) {
        await user.reload();
        final fresh = FirebaseAuth.instance.currentUser;
        verified = fresh?.emailVerified ?? false;
        if (verified) await fresh!.getIdToken(true);
      }
      if (!verified) return;

      await _firestore.collection('email_lookup').doc(email).set({
        'uid': user.uid,
      });
    } catch (_) {}
  }

  @override
  Future<String?> findUidByEmail(String email) async {
    final key = email.trim().toLowerCase();
    if (!_isValidKey(key)) return null;

    final snap = await _firestore
        .collection('email_lookup')
        .doc(key)
        .get(const GetOptions(source: Source.server));
    return snap.data()?['uid'] as String?;
  }

  bool _isValidKey(String email) =>
      email.length >= 3 &&
      email.length <= 254 &&
      email.contains('@') &&
      !email.contains('/');
}

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return FirestoreUserProfileRepository(FirebaseFirestore.instance);
});
