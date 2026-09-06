import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String _cloudinaryCloudName = 'r9rpj8jx';
const String _cloudinaryUploadPreset = 'mindscape_project';

abstract class NodeMediaRepository {
  Future<String> uploadNodeImage({
    required String mapId,
    required String nodeId,
    required String filePath,
  });

  Future<void> deleteNodeImage({required String mapId, required String nodeId});
}

class CloudinaryNodeMediaRepository implements NodeMediaRepository {
  CloudinaryNodeMediaRepository(this._dio);

  final Dio _dio;

  @override
  Future<String> uploadNodeImage({
    required String mapId,
    required String nodeId,
    required String filePath,
  }) async {
    final formData = FormData.fromMap({
      'upload_preset': _cloudinaryUploadPreset,
      'public_id': 'mindscape/$mapId/$nodeId',
      'file': await MultipartFile.fromFile(filePath, filename: '$nodeId.jpg'),
    });

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload',
        data: formData,
      );
      return response.data!['secure_url'] as String;
    } on DioException catch (e) {
      throw NodeMediaUploadException(
        'Cloudinary upload failed '
        '(${e.response?.statusCode}): ${e.message}',
      );
    }
  }

  @override
  Future<void> deleteNodeImage({
    required String mapId,
    required String nodeId,
  }) async {
    try {
      await _dio.delete(
        'https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/resources/image/mindscape/$mapId/$nodeId',
        queryParameters: {'invalidate': true},
      );
    } on DioException catch (e) {
      throw NodeMediaUploadException(
        'Cloudinary delete failed '
        '(${e.response?.statusCode}): ${e.message}',
      );
    }
  }
}

class NodeMediaUploadException implements Exception {
  NodeMediaUploadException(this.message);
  final String message;

  @override
  String toString() => message;
}

final nodeMediaRepositoryProvider = Provider<NodeMediaRepository>((ref) {
  return CloudinaryNodeMediaRepository(Dio());
});
