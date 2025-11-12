import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String? displayName;
  final String? email;
  final String? location;
  final String? phone;
  final String? photoUrl;
  final bool isHost;
  final int walletBalance;
  final DateTime? joinedAt;

  const UserModel({
    required this.uid,
    this.displayName,
    this.email,
    this.phone,
    this.photoUrl,
    this.location,
    this.isHost = false,
    this.walletBalance = 0,
    this.joinedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    DateTime? joined;
    final j = map['joinedAt'];
    if (j is Timestamp) {
      joined = j.toDate();
    } else if (j is int) {
      joined = DateTime.fromMillisecondsSinceEpoch(j);
    } else if (j is String) {
      joined = DateTime.tryParse(j);
    }

    return UserModel(
      uid: uid,
      displayName: map['displayName'] as String?,
      email: map['email'] as String?,
      location: map['location'] as String?,
      phone: map['phone'] as String?,
      photoUrl: map['photoUrl'] as String?,
      isHost: map['isHost'] == true,
      walletBalance: (map['walletBalance'] is int)
          ? map['walletBalance'] as int
          : (map['walletBalance'] is String)
          ? int.tryParse(map['walletBalance']) ?? 0
          : 0,
      joinedAt: joined,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'location': location,
      'phone': phone,
      'photoUrl': photoUrl,
      'isHost': isHost,
      'walletBalance': walletBalance,
      'joinedAt': joinedAt != null ? Timestamp.fromDate(joinedAt!) : null,
    };
  }
}
