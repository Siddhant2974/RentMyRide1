import 'dart:io' show File;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/car_model.dart';

class CarService {
  final CollectionReference _cars = FirebaseFirestore.instance.collection(
    'cars',
  );

  Stream<List<CarModel>> streamCarsByHost(String hostId) {
    // Use server-side ordering by createdAt (descending). Ensure Firestore index exists for this query.
    return _cars
        .where('hostId', isEqualTo: hostId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map(
                (d) => CarModel.fromMap(d.data() as Map<String, dynamic>, d.id),
              )
              .toList();
        });
  }

  /// Stream all active cars ordered by createdAt descending.
  Stream<List<CarModel>> streamAllCars() {
    return _cars.orderBy('createdAt', descending: true).snapshots().map((snap) {
      return snap.docs
          .map((d) => CarModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
    });
  }

  Future<String> uploadCarPhoto(String hostId, File file) async {
    final ref = FirebaseStorage.instance.ref().child(
      'cars/$hostId/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  Future<String> uploadCarPhotoBytes(String hostId, List<int> bytes) async {
    final ref = FirebaseStorage.instance.ref().child(
      'cars/$hostId/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final data = Uint8List.fromList(bytes);
    final task = await ref.putData(
      data,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return task.ref.getDownloadURL();
  }

  Future<DocumentReference> createCar(CarModel car) async {
    return await _cars.add(car.toMap());
  }

  Future<void> updateCar(CarModel car) async {
    await _cars.doc(car.id).set(car.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteCar(String carId) async {
    await _cars.doc(carId).delete();
  }

  // Favorites: store under users/{uid}/favorites/{carId}
  Future<void> addFavorite(String userId, String carId) async {
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(carId);
    await ref.set({'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> removeFavorite(String userId, String carId) async {
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(carId);
    await ref.delete();
  }

  Future<bool> isFavorite(String userId, String carId) async {
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(carId);
    final doc = await ref.get();
    return doc.exists;
  }
}
