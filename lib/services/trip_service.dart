import 'package:cloud_firestore/cloud_firestore.dart';

class TripService {
  final CollectionReference _trips = FirebaseFirestore.instance.collection(
    'trips',
  );

  Stream<List<Map<String, dynamic>>> streamTripsByUser(String userId) {
    // Fetch trips for user and sort client-side to avoid composite index requirement
    // Use server-side ordering by startAt (descending). Ensure Firestore index exists for this query.
    return _trips
        .where('userId', isEqualTo: userId)
        .orderBy('startAt', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs.map((d) {
            final m = d.data() as Map<String, dynamic>;
            m['id'] = d.id;
            return m;
          }).toList();
        });
  }

  Future<void> cancelTrip(String tripId) async {
    await _trips.doc(tripId).update({'status': 'Cancelled'});
  }

  Future<DocumentReference> createTrip(Map<String, dynamic> tripData) async {
    return await _trips.add(tripData);
  }
}
