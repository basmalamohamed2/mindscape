import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String _geminiApiKey =
    'AQ.Ab8RN6KHqba7kyXupZdiAEs2c3bw07bJ7sPcNKEL2ZIBvAPKqA';

const String _geminiEndpoint =
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent';

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
  GeminiSuggestionsRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<String>> suggestRelatedIdeas(String nodeText) async {
    final prompt =
        'You are helping brainstorm a mind map. The current idea/node is: '
        '"$nodeText". Suggest exactly 4 short, distinct sub-ideas that '
        'naturally branch off it (2-5 words each, no numbering, no '
        'punctuation at the end). '
        'Respond with ONLY a raw JSON array of 4 strings — no markdown '
        'code fences, no extra commentary. Example: '
        '["Idea one", "Idea two", "Idea three", "Idea four"]';

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _geminiEndpoint,
        queryParameters: {'key': _geminiApiKey},
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
        },
      );

      final candidates = response.data?['candidates'] as List<dynamic>?;
      final text = candidates?.isNotEmpty == true
          ? (candidates!.first['content']?['parts']?[0]?['text'] as String?)
          : null;

      if (text == null || text.trim().isEmpty) {
        throw AiSuggestionException('The model returned an empty response.');
      }

      return _parseSuggestions(text);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 400 &&
          (e.response?.data?.toString().contains('API key') ?? false)) {
        throw AiSuggestionException(
          'Invalid Gemini API key — check _geminiApiKey in '
          'ai_suggestions_repository.dart.',
        );
      }
      throw AiSuggestionException('Request failed ($status): ${e.message}');
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
        return decoded
            .map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    throw AiSuggestionException("Couldn't understand the model's response.");
  }
}

final aiSuggestionsRepositoryProvider = Provider<AiSuggestionsRepository>((
  ref,
) {
  return GeminiSuggestionsRepository(Dio());
});
