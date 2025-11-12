import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/car_model.dart';
import 'services/car_service.dart';
import 'models/user_model.dart';
import 'car_details_page.dart';

class AllCarsPage extends StatelessWidget {
  const AllCarsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final carService = CarService();
    final user = Provider.of<UserModel?>(context);

    return Scaffold(
      appBar: AppBar(title: Text('All Cars'), backgroundColor: Colors.orange),
      body: StreamBuilder<List<CarModel>>(
        stream: carService.streamAllCars(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final cars = snap.data ?? [];
          if (cars.isEmpty) return Center(child: Text('No cars listed yet'));
          return ListView.separated(
            padding: EdgeInsets.all(12),
            itemCount: cars.length,
            separatorBuilder: (_, __) => SizedBox(height: 12),
            itemBuilder: (context, index) {
              final car = cars[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange,
                    backgroundImage: car.photos.isNotEmpty
                        ? NetworkImage(car.photos.first)
                        : null,
                    child: car.photos.isEmpty
                        ? Icon(Icons.directions_car, color: Colors.white)
                        : null,
                  ),
                  title: Text(car.name),
                  subtitle: Text('${car.location} • ₹${car.pricePerDay}/day'),
                  onTap: () {
                    // Open rich car details page (with booking action)
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CarDetailsPage(car: car, currentUser: user),
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
