import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindspace/features/auth/logic/provider/auth_repository.dart';
import 'package:mindspace/models/mind_map_model.dart';

abstract class MindMapRepository {
  Stream<List<MindMap>> watchUserMindMaps(String uid);
  Future<String> createMindMap(String title, String ownerId);
  Future<void> deleteMindMap(String mapId);
  Future<void> leaveMindMap(String mapId, String uid);
  Future<void> renameMindMap(String mapId, String newTitle);
  Future<void> addCollaborator(String mapId, String collaboratorUid);
}

class FirestoreMindMapRepository implements MindMapRepository {
  FirestoreMindMapRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('mind_maps');

  @override
  Stream<List<MindMap>> watchUserMindMaps(String uid) {
    return _collection
        .where(
          Filter.or(
            Filter('userId', isEqualTo: uid),
            Filter('collaboratorIds', arrayContains: uid),
          ),
        )
        .orderBy('updatedAt', descending: true)
        .snapshots(includeMetadataChanges: true)
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
    final mapRef = _collection.doc(mapId);
    final nodes = await mapRef.collection('nodes').get();
    final refs = nodes.docs.map((d) => d.reference).toList();

    const chunkSize = 450;
    final commits = <Future<void>>[];
    for (var i = 0; i < refs.length; i += chunkSize) {
      final batch = _firestore.batch();
      for (final ref in refs.skip(i).take(chunkSize)) {
        batch.delete(ref);
      }
      commits.add(batch.commit());
    }
    commits.add(mapRef.delete());

    await Future.wait(commits);
  }

  @override
  Future<void> leaveMindMap(String mapId, String uid) async {
    await _collection.doc(mapId).update({
      'collaboratorIds': FieldValue.arrayRemove([uid]),
    });
  }

  @override
  Future<void> renameMindMap(String mapId, String newTitle) async {
    await _collection.doc(mapId).update({
      'title': newTitle,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> addCollaborator(String mapId, String collaboratorUid) async {
    await _collection.doc(mapId).update({
      'collaboratorIds': FieldValue.arrayUnion([collaboratorUid]),
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
