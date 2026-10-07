import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignInCancelledException implements Exception {
  const SignInCancelledException();
}

abstract class AuthRepository {
  Stream<User?> authStateChanges();
  User? get currentUser;

  Future<void> signInWithGoogle();
  Future<void> signInWithEmailAndPassword(String email, String password);
  Future<void> registerWithEmailAndPassword(String email, String password);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendEmailVerification();
  Future<void> signOut();

  bool get reauthNeedsPassword;

  Future<void> reauthenticate({String? password});

  Future<void> deleteCurrentUser();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInReady = false;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInReady) return;
    await _googleSignIn.initialize();
    _googleSignInReady = true;
  }

  @override
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<void> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();

    late final GoogleSignInAccount googleUser;
    try {
      googleUser = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const SignInCancelledException();
      }
      rethrow;
    }

    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    await _firebaseAuth.signInWithCredential(credential);
  }

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> sendEmailVerification() async {
    await _firebaseAuth.currentUser?.sendEmailVerification();
  }

  @override
  Future<void> signOut() async {
    try {
      await _ensureGoogleSignInInitialized();
      await _googleSignIn.signOut();
    } catch (_) {}
    await _firebaseAuth.signOut();
  }

  bool get _usesGoogle =>
      _firebaseAuth.currentUser?.providerData.any(
        (p) => p.providerId == 'google.com',
      ) ??
      false;

  @override
  bool get reauthNeedsPassword => !_usesGoogle;

  @override
  Future<void> reauthenticate({String? password}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-current-user');
    }

    if (_usesGoogle) {
      await _ensureGoogleSignInInitialized();
      late final GoogleSignInAccount googleUser;
      try {
        googleUser = await _googleSignIn.authenticate();
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled) {
          throw const SignInCancelledException();
        }
        rethrow;
      }
      final credential = GoogleAuthProvider.credential(
        idToken: googleUser.authentication.idToken,
      );
      await user.reauthenticateWithCredential(credential);
      return;
    }

    final email = user.email;
    if (email == null || password == null || password.isEmpty) {
      throw FirebaseAuthException(code: 'missing-password');
    }
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: email, password: password),
    );
  }

  @override
  Future<void> deleteCurrentUser() async {
    await _firebaseAuth.currentUser?.delete();
    await signOut(); // clears the Google session too
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(FirebaseAuth.instance);
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});
