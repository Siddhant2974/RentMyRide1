import 'package:flutter/material.dart';

class HostEarnPage extends StatelessWidget {
  const HostEarnPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mocked hosted cars data
    final hostedCars = [
      {'name': 'Toyota Innova Crysta', 'earnings': '₹12,500'},
      {'name': 'Maruti Swift', 'earnings': '₹6,400'},
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Host & Earn'), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to your Host dashboard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total earnings',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '₹18,900',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.add),
                      label: Text('List a car'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Your listed cars',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: hostedCars.length,
                separatorBuilder: (_, __) => Divider(),
                itemBuilder: (context, index) {
                  final car = hostedCars[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Icon(Icons.directions_car, color: Colors.white),
                    ),
                    title: Text(car['name']!),
                    subtitle: Text('Earnings: ${car['earnings']}'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {},
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
