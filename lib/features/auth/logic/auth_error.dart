import 'package:firebase_auth/firebase_auth.dart';

class AuthErrorMapper {
  const AuthErrorMapper._();

  static String map(Object error) {
    if (error is! FirebaseAuthException) {
      return 'Something went wrong. Please try again.';
    }

    switch (error.code) {
      case 'invalid-email':
        return "That email address doesn't look right.";
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'invalid-credential':
        return 'No account matches that email and password.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with that email — '
            'try signing in instead.';
      case 'weak-password':
        return 'Choose a stronger password (at least 6 characters).';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return "Couldn't reach the network. Check your connection "
            'and try again.';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled for this app.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
