import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mindspace/features/canvas/logic/provider/ai_suggestions_repository.dart';

class AiSuggestionsController extends StateNotifier<AsyncValue<List<String>>> {
  AiSuggestionsController(this._ref) : super(const AsyncData([]));

  final Ref _ref;

  Future<void> generate(String nodeText) async {
    state = const AsyncLoading();
    try {
      final suggestions = await _ref
          .read(aiSuggestionsRepositoryProvider)
          .suggestRelatedIdeas(nodeText);
      state = AsyncData(suggestions);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  void remove(String suggestion) {
    state.whenData((suggestions) {
      state = AsyncData(suggestions.where((s) => s != suggestion).toList());
    });
  }
}

final aiSuggestionsControllerProvider =
    StateNotifierProvider.autoDispose<
      AiSuggestionsController,
      AsyncValue<List<String>>
    >((ref) {
      return AiSuggestionsController(ref);
    });
