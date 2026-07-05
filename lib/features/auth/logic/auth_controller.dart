import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mindspace/features/auth/logic/provider/auth_repository.dart';

enum AuthAction { google, email }

final authPendingActionProvider = StateProvider<AuthAction?>((ref) => null);

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<void> signInWithGoogle() async {
    _ref.read(authPendingActionProvider.notifier).state = AuthAction.google;
    state = const AsyncLoading();
    final repository = _ref.read(authRepositoryProvider);

    try {
      await repository.signInWithGoogle();
      state = const AsyncData(null);
    } on SignInCancelledException {
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    } finally {
      _ref.read(authPendingActionProvider.notifier).state = null;
    }
  }

  Future<void> sendEmailSignInLink(String email) async {
    _ref.read(authPendingActionProvider.notifier).state = AuthAction.email;
    state = const AsyncLoading();
    final repository = _ref.read(authRepositoryProvider);

    try {
      await repository.sendEmailSignInLink(email);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    } finally {
      _ref.read(authPendingActionProvider.notifier).state = null;
    }
  }

  void clearError() {
    if (state.hasError) {
      state = const AsyncData(null);
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
      return AuthController(ref);
    });
