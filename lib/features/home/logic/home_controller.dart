import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mindspace/features/auth/logic/provider/auth_repository.dart';
import 'package:mindspace/features/home/logic/provider/mind_map_repository.dart';
import 'package:mindspace/models/mind_map_model.dart';

class HomeController extends StateNotifier<AsyncValue<String?>> {
  HomeController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<String?> createMindMap(String title) async {
    final user = _ref.read(authRepositoryProvider).currentUser;
    if (user == null) return null;

    state = const AsyncLoading();
    try {
      final id = await _ref
          .read(mindMapRepositoryProvider)
          .createMindMap(title, user.uid);
      state = AsyncData(id);
      return id;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  Future<void> removeMindMap(MindMap map) async {
    final user = _ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    state = const AsyncLoading();
    try {
      final repository = _ref.read(mindMapRepositoryProvider);
      if (map.ownerId == user.uid) {
        await repository.deleteMindMap(map.id);
      } else {
        await repository.leaveMindMap(map.id, user.uid);
      }
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  void clearError() {
    if (state.hasError) state = const AsyncData(null);
  }
}

final homeControllerProvider =
    StateNotifierProvider<HomeController, AsyncValue<String?>>((ref) {
      return HomeController(ref);
    });
