import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindspace/models/canvas_node_model.dart';

abstract class CanvasRepository {
  Stream<List<CanvasNode>> watchNodes(String mapId);
  Future<void> createNode(String mapId, CanvasNode node);
  Future<void> updateNodeFields(
    String mapId,
    String nodeId,
    Map<String, dynamic> fields,
  );
  Future<void> deleteNode(String mapId, String nodeId);

  Future<void> applyBatch({
    required String mapId,
    List<String> deletions,
    Map<String, Map<String, dynamic>> updates,
  });

  Stream<bool> watchSyncStatus(String mapId);
}

class FirestoreCanvasRepository implements CanvasRepository {
  FirestoreCanvasRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _nodesCollection(String mapId) {
    return _firestore.collection('mind_maps').doc(mapId).collection('nodes');
  }

  @override
  Stream<List<CanvasNode>> watchNodes(String mapId) {
    return _nodesCollection(mapId).snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => CanvasNode.fromMap(doc.data())).toList(),
    );
  }

  @override
  Future<void> createNode(String mapId, CanvasNode node) async {
    await _nodesCollection(mapId).doc(node.id).set(node.toMap());
  }

  @override
  Future<void> updateNodeFields(
    String mapId,
    String nodeId,
    Map<String, dynamic> fields,
  ) async {
    await _nodesCollection(mapId).doc(nodeId).update(fields);
  }

  @override
  Future<void> deleteNode(String mapId, String nodeId) async {
    await _nodesCollection(mapId).doc(nodeId).delete();
  }

  @override
  Future<void> applyBatch({
    required String mapId,
    List<String> deletions = const [],
    Map<String, Map<String, dynamic>> updates = const {},
  }) async {
    final batch = _firestore.batch();
    final collection = _nodesCollection(mapId);

    for (final id in deletions) {
      batch.delete(collection.doc(id));
    }
    for (final entry in updates.entries) {
      batch.update(collection.doc(entry.key), entry.value);
    }

    await batch.commit();
  }

  @override
  Stream<bool> watchSyncStatus(String mapId) {
    return _nodesCollection(mapId)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.metadata.hasPendingWrites);
  }
}

final canvasRepositoryProvider = Provider<CanvasRepository>((ref) {
  return FirestoreCanvasRepository(FirebaseFirestore.instance);
});
