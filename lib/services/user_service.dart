import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final CollectionReference _users = FirebaseFirestore.instance.collection(
    'users',
  );

  Stream<UserModel?> streamUser(String uid) {
    return _users.doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data() as Map<String, dynamic>;
      return UserModel.fromMap(data, snap.id);
    });
  }

  Future<UserModel?> fetchUser(String uid) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists) return null;
    return UserModel.fromMap(snap.data() as Map<String, dynamic>, snap.id);
  }

  Future<void> createOrUpdateUser(UserModel user) async {
    await _users.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }
}
