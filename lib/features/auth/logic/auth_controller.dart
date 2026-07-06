import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mindspace/features/auth/logic/provider/auth_repository.dart';

enum AuthAction { google, emailSignIn, emailRegister, passwordReset }

final authPendingActionProvider = StateProvider<AuthAction?>((ref) => null);

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  AuthRepository get _repository => _ref.read(authRepositoryProvider);

  Future<void> signInWithGoogle() {
    return _run(
      AuthAction.google,
      _repository.signInWithGoogle,
      ignoreCancellation: true,
    );
  }

  Future<void> signInWithEmail(String email, String password) {
    return _run(
      AuthAction.emailSignIn,
      () => _repository.signInWithEmailAndPassword(email, password),
    );
  }

  Future<void> registerWithEmail(String email, String password) {
    return _run(AuthAction.emailRegister, () async {
      await _repository.registerWithEmailAndPassword(email, password);
      await _repository.sendEmailVerification();
    });
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _run(
      AuthAction.passwordReset,
      () => _repository.sendPasswordResetEmail(email),
    );
  }

  Future<void> signOut() => _repository.signOut();

  Future<void> _run(
    AuthAction action,
    Future<void> Function() task, {
    bool ignoreCancellation = false,
  }) async {
    _ref.read(authPendingActionProvider.notifier).state = action;
    state = const AsyncLoading();

    try {
      await task();
      state = const AsyncData(null);
    } on SignInCancelledException {
      if (!ignoreCancellation) rethrow;
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    } finally {
      _ref.read(authPendingActionProvider.notifier).state = null;
    }
  }

  void clearError() {
    if (state.hasError) state = const AsyncData(null);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
      return AuthController(ref);
    });
