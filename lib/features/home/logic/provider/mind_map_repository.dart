import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindspace/features/auth/logic/provider/auth_repository.dart';
import 'package:mindspace/models/mind_map_model.dart';

abstract class MindMapRepository {
  Stream<List<MindMap>> watchUserMindMaps(String ownerId);

  Future<String> createMindMap(String title, String ownerId);

  Future<void> deleteMindMap(String mapId);
  Future<void> renameMindMap(String mapId, String newTitle);
}

class FirestoreMindMapRepository implements MindMapRepository {
  FirestoreMindMapRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('mind_maps');

  @override
  Stream<List<MindMap>> watchUserMindMaps(String ownerId) {
    return _collection
        .where('userId', isEqualTo: ownerId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(MindMap.fromFirestore).toList());
  }

  @override
  Future<String> createMindMap(String title, String ownerId) async {
    final doc = await _collection.add(
      MindMap.creationPayload(title: title, ownerId: ownerId),
    );
    return doc.id;
  }

  @override
  Future<void> deleteMindMap(String mapId) async {
    await _collection.doc(mapId).delete();
  }

  @override
  Future<void> renameMindMap(String mapId, String newTitle) async {
    await _collection.doc(mapId).update({
      'title': newTitle,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

final mindMapRepositoryProvider = Provider<MindMapRepository>((ref) {
  return FirestoreMindMapRepository(FirebaseFirestore.instance);
});

final userMindMapsProvider = StreamProvider.autoDispose<List<MindMap>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return const Stream<List<MindMap>>.empty();
  return ref.watch(mindMapRepositoryProvider).watchUserMindMaps(user.uid);
});
