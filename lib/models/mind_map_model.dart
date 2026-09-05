import 'package:cloud_firestore/cloud_firestore.dart';

class MindMap {
  const MindMap({
    required this.id,
    required this.title,
    required this.ownerId,
    required this.updatedAt,
    required this.collaboratorIds,
    this.hasPendingWrites = false,
  });

  final String id;
  final String title;
  final String ownerId;
  final DateTime updatedAt;
  final List<String> collaboratorIds;
  final bool hasPendingWrites;

  int get collaboratorCount => collaboratorIds.length;

  factory MindMap.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final timestamp = data['updatedAt'];

    return MindMap(
      id: doc.id,
      title: (data['title'] as String?) ?? 'Untitled map',
      ownerId: (data['userId'] as String?) ?? '',
      updatedAt: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
      collaboratorIds: List<String>.from(
        (data['collaboratorIds'] as List<dynamic>?) ?? const [],
      ),
      hasPendingWrites: doc.metadata.hasPendingWrites,
    );
  }

  static Map<String, dynamic> creationPayload({
    required String title,
    required String ownerId,
  }) {
    return {
      'title': title,
      'userId': ownerId,
      'collaboratorIds': <String>[],
      'nodes': <Map<String, dynamic>>[],
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
