import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

const String _geminiModelName = 'gemini-3.5-flash';

class AiSuggestionException implements Exception {
  AiSuggestionException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract class AiSuggestionsRepository {
  Future<List<String>> suggestRelatedIdeas(String nodeText);
}

class GeminiSuggestionsRepository implements AiSuggestionsRepository {
  GeminiSuggestionsRepository();

  GenerativeModel? _model;

  GenerativeModel get _generativeModel =>
      _model ??= FirebaseAI.googleAI().generativeModel(
        model: _geminiModelName,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: Schema.array(items: Schema.string()),
        ),
      );

  @override
  Future<List<String>> suggestRelatedIdeas(String nodeText) async {
    final prompt =
        'You are helping brainstorm a mind map. The current idea/node is: '
        '"$nodeText". Suggest exactly 4 short, distinct sub-ideas that '
        'naturally branch off it (2-5 words each, no numbering, no '
        'punctuation at the end). Respond with a JSON array of 4 strings.';

    try {
      final response = await _generativeModel.generateContent([
        Content.text(prompt),
      ]);

      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw AiSuggestionException('The model returned an empty response.');
      }
      return _parseSuggestions(text);
    } on AiSuggestionException {
      rethrow;
    } on FirebaseAIException catch (e) {
      debugPrint('AI error (FirebaseAIException): ${e.message}');
      throw AiSuggestionException(
        "Couldn't get suggestions right now. Please try again later.",
      );
    } catch (e, st) {
      debugPrint('AI error (other): $e\n$st');
      throw AiSuggestionException(
        "Couldn't get suggestions right now. Check your connection.",
      );
    }
  }

  List<String> _parseSuggestions(String rawText) {
    final cleaned = rawText
        .trim()
        .replaceAll(RegExp(r'^```json', multiLine: true), '')
        .replaceAll(RegExp(r'^```', multiLine: true), '')
        .replaceAll(RegExp(r'```$', multiLine: true), '')
        .trim();

    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is List) {
        final items = decoded
            .map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}
    throw AiSuggestionException("Couldn't understand the model's response.");
  }
}

final aiSuggestionsRepositoryProvider = Provider<AiSuggestionsRepository>((
  ref,
) {
  return GeminiSuggestionsRepository();
});
