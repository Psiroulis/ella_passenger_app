import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/rider.dart';

class UserProfileDataSource {
  late final FirebaseFirestore _db;

  UserProfileDataSource(this._db);

  Future<void> createRiderProfile(String uid, Rider rider) async {
    await _db.collection('riders').doc(uid).set(rider.toMap());
  }

  Future<void> updateRiderProfile(
    String uid, {
    String? phone,
    String? name,
  }) async {
    final doc = _db.collection('riders').doc(uid);
    await doc.set({
      'phone': phone,
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> loginToUserProfile(String uid, String phone) async {
    final snap = await _db.collection('riders').doc(uid).get();

    if (!snap.exists) {
      await createRiderProfile(uid, Rider(uid: uid, phone: phone));
    }
    }

  Future<Rider?> getRiderProfile(String uid) async {
    final snap = await _db.collection('riders').doc(uid).get();
    return snap.exists ? Rider.fromMap(snap.data()!) : null;
  }
}
