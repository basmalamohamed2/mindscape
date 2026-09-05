import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindspace/models/canvas_node_model.dart';

abstract class CanvasRepository {
  Stream<List<CanvasNode>> watchNodes(String mapId);
  Future<void> saveNodes(String mapId, List<CanvasNode> nodes);
}

class FirestoreCanvasRepository implements CanvasRepository {
  FirestoreCanvasRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String mapId) =>
      _firestore.collection('mind_maps').doc(mapId);

  @override
  Stream<List<CanvasNode>> watchNodes(String mapId) {
    return _doc(mapId).snapshots().map((snapshot) {
      final data = snapshot.data();
      final rawNodes = data?['nodes'] as List<dynamic>? ?? const [];
      return rawNodes
          .cast<Map<String, dynamic>>()
          .map(CanvasNode.fromMap)
          .toList();
    });
  }

  @override
  Future<void> saveNodes(String mapId, List<CanvasNode> nodes) async {
    await _doc(mapId).update({
      'nodes': nodes.map((n) => n.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

final canvasRepositoryProvider = Provider<CanvasRepository>((ref) {
  return FirestoreCanvasRepository(FirebaseFirestore.instance);
});
