import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'host_earn_page.dart';
import 'package:provider/provider.dart';
import 'models/user_model.dart';
import 'services/user_service.dart';
import 'services/car_service.dart';
import 'models/car_model.dart';
import 'all_cars_page.dart';
import 'theme.dart';
import 'widgets/search_bar.dart';
import 'widgets/header_widget.dart';

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
    // Provide a ThemeNotifier for runtime theme switching and use AppTheme
    return ChangeNotifierProvider<ThemeNotifier>(
      create: (_) => ThemeNotifier(),
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeNotifier.themeMode,
            home: AuthGate(),
            routes: {
              // Named route so LoginPage can navigate to the main screen without importing main.dart
              '/main': (context) => MainScreen(),
            },
          );
        },
      ),
    );
  }
}

/// Shows [LoginPage] when user is not signed in, else shows [MainScreen].
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

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
          // Ensure a Firestore user doc exists for this auth user (create if missing).
          // We schedule this as a microtask so it doesn't block the build.
          Future.microtask(() async {
            try {
              final u = await UserService().fetchUser(uid);
              if (u == null) {
                final authUser = snapshot.data!;
                final newUser = UserModel(
                  uid: uid,
                  displayName: authUser.displayName,
                  email: authUser.email,
                  location: null,
                );
                await UserService().createOrUpdateUser(newUser);
              }
            } catch (_) {}
          });
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
    // All Cars page
    AllCarsPage(),
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
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            color:
                Theme.of(context).bottomNavigationBarTheme.backgroundColor ??
                Colors.white,
            boxShadow: [
              BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.04), blurRadius: 8),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.directions_car),
                label: 'All Cars',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.attach_money),
                label: 'Host & Earn',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CarService _carService = CarService();
  String _searchQuery = '';

  void _filterCars(String query) {
    setState(() {
      _searchQuery = query.toLowerCase().trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Restored fuller Home UI (kept moderately simple and safe) while we continue the revamp.
    final userModel = Provider.of<UserModel?>(context);
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).scaffoldBackgroundColor,
                Theme.of(
                  context,
                ).scaffoldBackgroundColor.withAlpha((0.98 * 255).round()),
              ],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              HeaderWidget(userModel: userModel),
              const SizedBox(height: 16),

              // Search
              AppSearchBar(onChanged: _filterCars),
              const SizedBox(height: 12),

              // Horizontal search results
              StreamBuilder<List<CarModel>>(
                stream: _carService.streamAllCars(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 140,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError) return const SizedBox.shrink();
                  final all = snap.data ?? [];
                  final filtered = all.where((c) {
                    final q = _searchQuery;
                    if (q.isEmpty) return true;
                    return c.name.toLowerCase().contains(q) ||
                        c.location.toLowerCase().contains(q);
                  }).toList();
                  if (filtered.isEmpty) return const SizedBox.shrink();
                  return SizedBox(
                    height: 140,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final car = filtered[index];
                        return Container(
                          width: 260,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.directions_car,
                                size: 48,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      car.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(car.location),
                                    const SizedBox(height: 6),
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
                  );
                },
              ),

              const SizedBox(height: 16),

              // Featured card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9C4),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(255, 152, 0, 0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.directions_car, size: 48, color: Colors.orange),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Featured Car',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Toyota Innova Crysta - Spacious, comfortable, and perfect for family trips!',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Drive type cards
              Row(
                children: const [
                  Expanded(
                    child: DriveCard(
                      title: 'DAILY DRIVES',
                      subtitle: 'Drive Unlimited, 4 hrs or more',
                      days: 'Upto 7 Days',
                      icon: Icons.timer,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: DriveCard(
                      title: 'SUBSCRIPTION',
                      subtitle: 'Longer Duration, Higher Discount',
                      days: '7+ Days',
                      icon: Icons.calendar_today,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Host & Earn preview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 128, 0, 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HOST & EARN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Turn your idle car into a steady income stream',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.payment),
                            label: const Text('Dashboard access'),
                            style: ElevatedButton.styleFrom(
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

              const SizedBox(height: 20),

              // Rewards
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Rewards worth up to ₹2000 await!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text('Your surprise is locked for now.'),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Why RentMyRide
              const Text(
                'WHY RENTMYRIDE ?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  FeatureCard(
                    icon: Icons.verified,
                    text: '100% Hassle free Secured Trip',
                  ),
                  SizedBox(width: 16),
                  FeatureCard(icon: Icons.public, text: 'Anywhere Anytime'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  FeatureCard(
                    icon: Icons.access_time,
                    text: 'Endless Pay by hour drive limitless',
                  ),
                  SizedBox(width: 16),
                  FeatureCard(
                    icon: Icons.star,
                    text: 'Quality Cars in the city',
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// Lightweight, safe replacements for previously refactored cards.
// DriveCard (interactive) implemented below.
class DriveCard extends StatefulWidget {
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
  State<DriveCard> createState() => _DriveCardState();
}

class _DriveCardState extends State<DriveCard> {
  bool _pressed = false;

  void _onTapDown(_) => setState(() => _pressed = true);
  void _onTapUp(_) => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).cardColor;
    final primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: '${widget.title} card',
      button: true,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {},
        child: AnimatedContainer(
          duration: AppTheme.shortAnimation,
          padding: const EdgeInsets.all(12),
          transform: (() {
            final s = _pressed ? 0.98 : 1.0;
            return Matrix4.diagonal3Values(s, s, 1.0);
          })(),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, _pressed ? 0.08 : 0.04),
                blurRadius: _pressed ? 12 : 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 40,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 8),
              Text(
                widget.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(widget.subtitle, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withAlpha((0.12 * 255).round()),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(widget.days, style: TextStyle(color: primary)),
              ),
            ],
          ),
        ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Removed in-file MyTripsPage and ProfilePage classes ---
