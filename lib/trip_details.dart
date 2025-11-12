import 'package:flutter/material.dart';

class TripDetailsPage extends StatelessWidget {
  final Map<String, dynamic> trip;

  const TripDetailsPage({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trip details'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.orange[100],
                child: Icon(
                  trip['image'] as IconData,
                  color: Colors.orange,
                  size: 32,
                ),
              ),
              title: Text(
                trip['car'] as String,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${trip['location']} • ${trip['date']}'),
            ),
            SizedBox(height: 16),
            Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (trip['status'] as String) == 'Upcoming'
                    ? Colors.green[100]
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                trip['status'] as String,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 20),
            Text('Trip summary', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              'This screen can hold more details about the trip, payment summary, host contact and actions such as cancel or view invoice.',
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.arrow_back),
              label: Text('Back'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }
}
