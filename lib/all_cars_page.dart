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
      appBar: AppBar(title: const Text('All Cars')),
      body: StreamBuilder<List<CarModel>>(
        stream: carService.streamAllCars(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final cars = snap.data ?? [];
          if (cars.isEmpty) {
            return const Center(child: Text('No cars listed yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: cars.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final car = cars[index];
              return Semantics(
                label: '${car.name}, ${car.location}',
                button: true,
                child: Card(
                  elevation: 4,
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CarDetailsPage(car: car, currentUser: user),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withAlpha((0.15 * 255).round()),
                            backgroundImage: car.photos.isNotEmpty
                                ? NetworkImage(car.photos.first)
                                : null,
                            child: car.photos.isEmpty
                                ? Icon(
                                    Icons.directions_car,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  car.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${car.location} • ₹${car.pricePerDay}/day',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
