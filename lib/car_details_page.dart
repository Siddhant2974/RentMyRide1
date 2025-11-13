import 'package:flutter/material.dart';
// lightweight date formatting (avoid adding intl dependency)
import 'models/car_model.dart';
import 'models/user_model.dart';
import 'services/user_service.dart';
import 'services/car_service.dart';
import 'host_earn_page.dart';
import 'booking_page.dart';

class CarDetailsPage extends StatefulWidget {
  final CarModel car;
  final UserModel? currentUser;

  const CarDetailsPage({super.key, required this.car, this.currentUser});

  @override
  State<CarDetailsPage> createState() => _CarDetailsPageState();
}

class _CarDetailsPageState extends State<CarDetailsPage> {
  int _page = 0;
  UserModel? _host;
  bool _loadingHost = true;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadHost();
    _loadFavorite();
  }

  Future<void> _loadHost() async {
    try {
      final host = await UserService().fetchUser(widget.car.hostId);
      if (mounted) {
        setState(() {
          _host = host;
          _loadingHost = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingHost = false);
      }
    }
  }

  Future<void> _loadFavorite() async {
    final user = widget.currentUser;
    if (user == null) return;
    try {
      final fav = await CarService().isFavorite(user.uid, widget.car.id);
      if (mounted) {
        setState(() => _isFavorite = fav);
      }
    } catch (_) {}
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    final d = dt.toLocal();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;
    final photos = car.photos;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top image area
            SizedBox(
              height: 260,
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: photos.isNotEmpty ? photos.length : 1,
                    onPageChanged: (p) => setState(() => _page = p),
                    itemBuilder: (context, index) {
                      if (photos.isEmpty) {
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Icon(
                              Icons.directions_car,
                              size: 80,
                              color: Colors.grey[600],
                            ),
                          ),
                        );
                      }
                      final url = photos[index];
                      return Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(url),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: CircleAvatar(
                      backgroundColor: Color.fromRGBO(0, 0, 0, 0.4),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: CircleAvatar(
                      backgroundColor: Color.fromRGBO(0, 0, 0, 0.4),
                      child: IconButton(
                        icon: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: Colors.white,
                        ),
                        onPressed: () async {
                          final user = widget.currentUser;
                          if (user == null) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Sign in to save favorites'),
                                ),
                              );
                            }
                            return;
                          }
                          setState(() => _isFavorite = !_isFavorite);
                          try {
                            if (_isFavorite) {
                              await CarService().addFavorite(
                                user.uid,
                                widget.car.id,
                              );
                            } else {
                              await CarService().removeFavorite(
                                user.uid,
                                widget.car.id,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() => _isFavorite = !_isFavorite);
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update favorite'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ),
                  if (photos.isNotEmpty)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(photos.length, (i) {
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            width: _page == i ? 10 : 6,
                            height: _page == i ? 10 : 6,
                            decoration: BoxDecoration(
                              color: _page == i ? Colors.white : Colors.white54,
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),

            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  car.name,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  '${car.location} • ${car.isActive ? 'Available' : 'Inactive'}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${car.pricePerDay}/day',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Host info
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (context.mounted) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => HostEarnPage(
                                      hostIdParam: widget.car.hostId,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: CircleAvatar(
                              radius: 20,
                              backgroundImage: _host?.photoUrl != null
                                  ? NetworkImage(_host!.photoUrl!)
                                  : null,
                              backgroundColor: Colors.orange,
                              child: _host?.photoUrl == null
                                  ? Icon(Icons.person, color: Colors.white)
                                  : null,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _host?.displayName ?? 'Host',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  _loadingHost
                                      ? 'Loading host...'
                                      : (_host?.email ?? ''),
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                          if (_host != null)
                            Text(
                              'Joined ${_formatDate(_host!.joinedAt)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),

                      SizedBox(height: 18),

                      // Description placeholder
                      Text(
                        'About this car',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(car.description ?? 'No description provided.'),

                      SizedBox(height: 24),

                      // Key details
                      Row(
                        children: [
                          _DetailChip(
                            icon: Icons.event,
                            label: 'Since',
                            value: _formatDate(car.createdAt),
                          ),
                          SizedBox(width: 8),
                          _DetailChip(
                            icon: Icons.speed,
                            label: 'Seats',
                            value: '${car.seats}',
                          ),
                          SizedBox(width: 8),
                          _DetailChip(
                            icon: Icons.local_gas_station,
                            label: 'Fuel',
                            value: car.fuelType,
                          ),
                        ],
                      ),

                      SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _showBookingSummary(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Book Now',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBookingSummary() async {
    int days = 1;
    final car = widget.car;
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final estimate = (car.pricePerDay * days);
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Text(car.name, style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Days:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(width: 12),
                      IconButton(
                        onPressed: () {
                          if (days > 1) setState(() => days--);
                        },
                        icon: Icon(Icons.remove),
                      ),
                      Text('$days'),
                      IconButton(
                        onPressed: () => setState(() => days++),
                        icon: Icon(Icons.add),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('Price per day: ₹${car.pricePerDay}'),
                  SizedBox(height: 8),
                  Text(
                    'Estimated total: ₹$estimate',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Cancel'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(this.context).push(
                              MaterialPageRoute(
                                builder: (_) => BookingPage(
                                  car: car,
                                  userModel: widget.currentUser,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: Text('Continue to booking'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.orange),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
