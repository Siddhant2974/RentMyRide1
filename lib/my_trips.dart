import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/user_model.dart';
import 'trip_details.dart';
import 'services/trip_service.dart';

class MyTripsPage extends StatefulWidget {
  const MyTripsPage({super.key});

  @override
  State<MyTripsPage> createState() => _MyTripsPageState();
}

class _MyTripsPageState extends State<MyTripsPage> {
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    final TripService tripService = TripService();

    // If the Firestore-backed user doc isn't available yet, fall back to
    // FirebaseAuth currentUser so trips can still be shown (e.g. immediately
    // after booking when the Firestore doc hasn't been created).
    final authUser = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? authUser?.uid;

    if (uid == null) {
      return Scaffold(
        body: Center(child: Text('Please sign in to see your bookings')),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF6F8FA),
      appBar: AppBar(
        elevation: 0,
        title: Text("My Trips", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_alt_outlined, color: Colors.white),
            onPressed: () {
              // TODO: Add filter functionality
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // include reload in key so pressing Retry rebuilds the stream subscription
        stream: tripService.streamTripsByUser(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (snap.hasError) {
            // show the actual error message to help debugging (index or permission links)
            final err = snap.error;
            // also log to console
            debugPrint('MyTrips stream error: $err');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Error loading trips',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('$err', textAlign: TextAlign.center),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => setState(() => _reload++),
                      child: Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          final trips = snap.data ?? [];
          if (trips.isEmpty) return Center(child: Text('No trips yet.'));
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              return Container(
                margin: EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.secondary.withOpacity(0.15),
                    child: Icon(
                      Icons.directions_car,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 32,
                    ),
                  ),
                  title: Text(
                    trip['carName'] ?? 'Car',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Text(trip['date'] ?? ''),
                        ],
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Text(trip['location'] ?? ''),
                        ],
                      ),
                      SizedBox(height: 6),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (trip['status'] ?? '') == 'Upcoming'
                              ? Theme.of(
                                  context,
                                ).colorScheme.secondary.withOpacity(0.12)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (trip['status'] ?? ''),
                          style: TextStyle(
                            color: (trip['status'] ?? '') == 'Upcoming'
                                ? Theme.of(context).colorScheme.secondary
                                : Colors.grey[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 20,
                    color: Colors.orange,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TripDetailsPage(trip: trip),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
