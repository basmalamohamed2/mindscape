import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindspace/features/home/logic/provider/mind_map_repository.dart';

class AccountDataRepository {
  AccountDataRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const _fromServer = GetOptions(source: Source.server);

  Future<void> deleteAllUserData({required String uid, String? email}) async {
    final maps = _firestore.collection('mind_maps');
    final mapRepository = FirestoreMindMapRepository(_firestore);

    final owned = await maps.where('userId', isEqualTo: uid).get(_fromServer);
    for (final doc in owned.docs) {
      await mapRepository.deleteMindMap(doc.id);
    }

    final shared = await maps
        .where('collaboratorIds', arrayContains: uid)
        .get(_fromServer);
    for (final doc in shared.docs) {
      if (doc.data()['userId'] == uid) continue;
      await mapRepository.leaveMindMap(doc.id, uid);
    }

    final key = email?.toLowerCase();
    if (key != null && key.isNotEmpty && !key.contains('/')) {
      final lookup = _firestore.collection('email_lookup').doc(key);
      final entry = await lookup.get(_fromServer);
      if (entry.data()?['uid'] == uid) await lookup.delete();
    }
    await _firestore.collection('users').doc(uid).delete();
  }
}

final accountDataRepositoryProvider = Provider<AccountDataRepository>((ref) {
  return AccountDataRepository(FirebaseFirestore.instance);
});
