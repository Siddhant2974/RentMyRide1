import 'package:flutter/material.dart';
import 'trip_details.dart';

class MyTripsPage extends StatelessWidget {
  const MyTripsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final trips = [
      {
        "car": "Toyota Innova Crysta",
        "date": "12 Oct 2025",
        "location": "Nashik",
        "status": "Upcoming",
        "image": Icons.directions_car,
      },
      {
        "car": "Hyundai i20",
        "date": "02 Sep 2025",
        "location": "Pune",
        "status": "Completed",
        "image": Icons.directions_car,
      },
    ];

    return Scaffold(
      backgroundColor: Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: Colors.orange,
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
      body: trips.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.airport_shuttle,
                    size: 64,
                    color: Colors.orange[200],
                  ),
                  SizedBox(height: 16),
                  Text(
                    "No trips yet.",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Start your first booking!",
                    style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.08),
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
                      backgroundColor: Colors.orange[100],
                      child: Icon(
                        trip["image"] as IconData,
                        color: Colors.orange,
                        size: 32,
                      ),
                    ),
                    title: Text(
                      trip["car"] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
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
                            Text(
                              trip["date"] as String,
                              style: TextStyle(fontSize: 13),
                            ),
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
                            Text(
                              trip["location"] as String,
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (trip["status"] as String) == "Upcoming"
                                ? Colors.green[100]
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            trip["status"] as String,
                            style: TextStyle(
                              color: (trip["status"] as String) == "Upcoming"
                                  ? Colors.green[800]
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
            ),
    );
  }
}
