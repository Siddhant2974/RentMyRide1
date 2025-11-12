import 'package:cloud_firestore/cloud_firestore.dart';

class CarModel {
  final String id;
  final String hostId;
  final String name;
  final String location;
  final String? description;
  final int pricePerDay;
  final int seats;
  final String fuelType;
  final List<String> photos;
  final bool isActive;
  final DateTime? createdAt;

  CarModel({
    required this.id,
    required this.hostId,
    required this.name,
    required this.location,
    this.description,
    required this.pricePerDay,
    this.seats = 5,
    this.fuelType = 'Petrol',
    this.photos = const [],
    this.isActive = true,
    this.createdAt,
  });

  factory CarModel.fromMap(Map<String, dynamic> map, String id) {
    final ca = map['createdAt'];
    DateTime? created;
    if (ca is Timestamp) created = ca.toDate();
    return CarModel(
      id: id,
      hostId: map['hostId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      location: map['location'] as String? ?? '',
      description: map['description'] as String?,
      pricePerDay: (map['pricePerDay'] is int)
          ? map['pricePerDay'] as int
          : int.tryParse('${map['pricePerDay']}') ?? 0,
      seats: (map['seats'] is int)
          ? map['seats'] as int
          : int.tryParse('${map['seats']}') ?? 5,
      fuelType: map['fuelType'] as String? ?? 'Petrol',
      photos: (map['photos'] as List<dynamic>?)?.cast<String>() ?? [],
      isActive: map['isActive'] == true,
      createdAt: created,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostId': hostId,
      'description': description,
      'name': name,
      'location': location,
      'pricePerDay': pricePerDay,
      'seats': seats,
      'fuelType': fuelType,
      'photos': photos,
      'isActive': isActive,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
