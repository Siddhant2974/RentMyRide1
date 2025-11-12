import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'my_trips.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'host_earn_page.dart';
import 'package:provider/provider.dart';
import 'models/user_model.dart';
import 'services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Set Firebase Auth language to avoid "X-Firebase-Locale" null header warnings.
  FirebaseAuth.instance.setLanguageCode('en');

  // App Check activation: force debug provider on Android emulator, default otherwise.
  try {
    if (!kIsWeb && Platform.isAndroid) {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
      );
      debugPrint('AppCheck: activated android debug provider.');
    } else {
      await FirebaseAppCheck.instance.activate();
      debugPrint('AppCheck: activated default provider.');
    }
  } catch (e) {
    debugPrint('AppCheck activation error: $e');
  }
  runApp(RentMyRideApp());
}

class RentMyRideApp extends StatelessWidget {
  const RentMyRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use authentication gate (show LoginPage when not signed in)
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthGate(),
      routes: {
        // Named route so LoginPage can navigate to the main screen without importing main.dart
        '/main': (context) => MainScreen(),
      },
    );
  }
}

/// Shows [LoginPage] when user is not signed in, else shows [MainScreen].
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData && snapshot.data != null) {
          final uid = snapshot.data!.uid;
          // Provide the Firestore-backed UserModel stream to the widget tree
          return StreamProvider<UserModel?>.value(
            value: UserService().streamUser(uid),
            initialData: null,
            catchError: (_, __) => null,
            child: MainScreen(),
          );
        }

        return LoginPage();
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    MyTripsPage(), // Use your custom My Trips page
    ProfilePage(), // Profile page
    HostEarnPage(), // Host & Earn page
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'My Trips',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Host & Earn',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class Car {
  final String name;
  final String location;
  final int pricePerDay;

  const Car({
    required this.name,
    required this.location,
    required this.pricePerDay,
  });
}

class _HomePageState extends State<HomePage> {
  final List<Car> _allCars = const [
    Car(name: 'Toyota Innova Crysta', location: 'Nashik', pricePerDay: 2500),
    Car(name: 'Maruti Swift', location: 'Nashik', pricePerDay: 1200),
    Car(name: 'Hyundai Creta', location: 'Mumbai', pricePerDay: 2200),
    Car(name: 'Mahindra Scorpio', location: 'Pune', pricePerDay: 2100),
  ];

  List<Car> _filteredCars = [];

  @override
  void initState() {
    super.initState();
    _filteredCars = List.from(_allCars);
  }

  void _filterCars(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _filteredCars = List.from(_allCars);
      } else {
        _filteredCars = _allCars.where((c) {
          return c.name.toLowerCase().contains(q) ||
              c.location.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F8FA),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hi there!",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          "Finding your drive in ",
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          "Nashik",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
                CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.monetization_on, color: Colors.white),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: "Search car or location",
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterCars,
            ),

            SizedBox(height: 12),

            // Search results (horizontal list)
            if (_filteredCars.isNotEmpty)
              Container(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filteredCars.length,
                  separatorBuilder: (_, __) => SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final car = _filteredCars[index];
                    return Container(
                      width: 260,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            blurRadius: 6,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.directions_car,
                            size: 48,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  car.name,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 6),
                                Text(car.location),
                                SizedBox(height: 6),
                                Text(
                                  '₹${car.pricePerDay}/day',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            SizedBox(height: 16),
            // Offer Card
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[600],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.15),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Earn guaranteed credits up to Rs.1500 after completing your first booking!",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "SPECIAL OFFER",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Featured Car Section
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFFFF9C4),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.10),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.directions_car, size: 48, color: Colors.orange),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Featured Car",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          "Toyota Innova Crysta - Spacious, comfortable, and perfect for family trips!",
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 18, color: Colors.orange),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Top Rated Hosts
            Container(
              alignment: Alignment.center,
              child: Text(
                "✨ Top Rated Verified hosts ✨",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            SizedBox(height: 16),
            // Self Drive Section
            Row(
              children: [
                Expanded(
                  child: DriveCard(
                    title: "DAILY DRIVES",
                    subtitle: "Drive Unlimited, 4 hrs or more",
                    days: "Upto 7 Days",
                    icon: Icons.timer,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DriveCard(
                    title: "SUBSCRIPTION",
                    subtitle: "Longer Duration, Higher Discount",
                    days: "7+ Days",
                    icon: Icons.calendar_today,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Host & Earn
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 1.5),
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.08),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "HOST & EARN",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text("Turn your idle car into a steady income stream"),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.payment),
                          label: Text("Dashboard access"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Rewards Section
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.card_giftcard, size: 48, color: Colors.green),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Rewards worth up to ₹2000 await!",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text("Your surprise is locked for now."),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 18, color: Colors.green),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Why RentMyRide Section
            Text(
              "WHY RENTMYRIDE ?",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                FeatureCard(
                  icon: Icons.verified,
                  text: "100% Hassle free Secured Trip",
                ),
                SizedBox(width: 16),
                FeatureCard(icon: Icons.public, text: "Anywhere Anytime"),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                FeatureCard(
                  icon: Icons.access_time,
                  text: "Endless Pay by hour drive limitless",
                ),
                SizedBox(width: 16),
                FeatureCard(icon: Icons.star, text: "Quality Cars in the city"),
              ],
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class DriveCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String days;
  final IconData icon;

  const DriveCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.days,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 50, color: Colors.orange),
          SizedBox(height: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center),
          SizedBox(height: 6),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(days, style: TextStyle(color: Colors.purple[800])),
          ),
        ],
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const FeatureCard({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.orange),
          SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// --- Removed in-file MyTripsPage and ProfilePage classes ---
