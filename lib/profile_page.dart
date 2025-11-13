import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'models/user_model.dart';
import 'login_page.dart';
import 'services/user_service.dart';
import 'host_earn_page.dart';
import 'my_trips.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _editing = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  bool _saving = false;
  String? _uploadedPhotoUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _locationController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _startEdit(UserModel? userModel) async {
    _nameController.text =
        userModel?.displayName ??
        FirebaseAuth.instance.currentUser?.displayName ??
        '';
    _phoneController.text = userModel?.phone ?? '';
    _locationController.text = userModel?.location ?? '';
    setState(() {
      _editing = true;
    });
  }

  Future<void> _save(UserModel? userModel) async {
    if (!_formKey.currentState!.validate()) return;
    final uid = userModel?.uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to determine user id.')));
      return;
    }

    setState(() {
      _saving = true;
    });

    final updated = UserModel(
      uid: uid,
      displayName: _nameController.text.trim(),
      email: userModel?.email ?? FirebaseAuth.instance.currentUser?.email,
      location: _locationController.text.trim(),
      phone: _phoneController.text.trim(),
      photoUrl: userModel?.photoUrl,
      isHost: userModel?.isHost ?? false,
      walletBalance: userModel?.walletBalance ?? 0,
      joinedAt: userModel?.joinedAt,
    );

    final scaffold = ScaffoldMessenger.of(context);
    try {
      await UserService().createOrUpdateUser(updated);
      if (mounted) {
        scaffold.showSnackBar(SnackBar(content: Text('Profile updated')));
      }
      setState(() {
        _editing = false;
      });
    } catch (e) {
      if (mounted) {
        scaffold.showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadPhoto(UserModel? userModel) async {
    final picker = ImagePicker();
    final scaffold = ScaffoldMessenger.of(context);
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    try {
      setState(() => _saving = true);
      final uid = userModel?.uid ?? FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw 'No user id';

      String downloadUrl;
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        final ref = FirebaseStorage.instance.ref().child(
          'avatars/$uid/${DateTime.now().millisecondsSinceEpoch}',
        );
        final uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        final snap = await uploadTask;
        downloadUrl = await snap.ref.getDownloadURL();
      } else {
        final file = File(picked.path);
        final ref = FirebaseStorage.instance.ref().child(
          'avatars/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        final uploadTask = ref.putFile(file);
        final snap = await uploadTask;
        downloadUrl = await snap.ref.getDownloadURL();
      }

      // update Firestore user doc
      final updated = UserModel(
        uid: uid,
        displayName: _nameController.text.isNotEmpty
            ? _nameController.text
            : userModel?.displayName,
        email: userModel?.email ?? FirebaseAuth.instance.currentUser?.email,
        location: _locationController.text.isNotEmpty
            ? _locationController.text
            : userModel?.location,
        phone: _phoneController.text.isNotEmpty
            ? _phoneController.text
            : userModel?.phone,
        photoUrl: downloadUrl,
        isHost: userModel?.isHost ?? false,
        walletBalance: userModel?.walletBalance ?? 0,
        joinedAt: userModel?.joinedAt,
      );

      await UserService().createOrUpdateUser(updated);

      // update FirebaseAuth profile if possible
      try {
        final authUser = FirebaseAuth.instance.currentUser;
        if (authUser != null) {
          await authUser.updatePhotoURL(downloadUrl);
        }
      } catch (_) {}

      if (mounted) {
        scaffold.showSnackBar(SnackBar(content: Text('Profile photo updated')));
      }
    } catch (e) {
      if (mounted) {
        scaffold.showSnackBar(
          SnackBar(content: Text('Photo upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel?>(context);
    final authUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text("My Profile"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: () {
              // toggle theme
              // use provider ThemeNotifier if available
              try {
                final notifier = Provider.of<ThemeNotifier>(
                  context,
                  listen: false,
                );
                notifier.toggle();
              } catch (_) {}
            },
          ),
          IconButton(icon: Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Profile Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.04),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 38,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                        backgroundImage: (_uploadedPhotoUrl != null)
                            ? NetworkImage(_uploadedPhotoUrl!) as ImageProvider
                            : (userModel?.photoUrl != null)
                            ? NetworkImage(userModel!.photoUrl!)
                            : null,
                        child:
                            (_uploadedPhotoUrl == null &&
                                (userModel?.photoUrl == null))
                            ? Icon(Icons.person, size: 48, color: Colors.white)
                            : null,
                      ),
                    ),
                    Positioned(
                      right: -6,
                      bottom: -6,
                      child: IconButton(
                        icon: Icon(Icons.camera_alt, color: Colors.white),
                        color: Theme.of(context).colorScheme.secondary,
                        onPressed: () => _pickAndUploadPhoto(userModel),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 18),
                Expanded(
                  child: _editing
                      ? _buildEditForm(userModel)
                      : _buildReadOnly(userModel, authUser),
                ),
                IconButton(
                  icon: Icon(
                    _editing ? Icons.close : Icons.edit,
                    color: Colors.orange,
                  ),
                  onPressed: () {
                    if (_editing) {
                      setState(() => _editing = false);
                    } else {
                      _startEdit(userModel);
                    }
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          // Quick Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatCard(
                icon: Icons.directions_car,
                label: "Cars Listed",
                value: "—",
              ),
              _StatCard(icon: Icons.book_online, label: "Bookings", value: "—"),
              _StatCard(
                icon: Icons.credit_score,
                label: "Credits",
                value: userModel != null ? '₹${userModel.walletBalance}' : '—',
              ),
            ],
          ),
          SizedBox(height: 24),
          // My Actions
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.directions_car, color: Colors.orange),
                  title: Text("My Listed Cars"),
                  subtitle: Text("Manage your car listings"),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              HostEarnPage(hostIdParam: userModel?.uid),
                        ),
                      );
                    }
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.book_online, color: Colors.orange),
                  title: Text("My Bookings"),
                  subtitle: Text("View your rental history"),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    if (context.mounted) {
                      Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => MyTripsPage()));
                    }
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.credit_card, color: Colors.orange),
                  title: Text("Credits & Rewards"),
                  subtitle: Text("Check your earned credits"),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          // Team & Project Info
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(128, 128, 128, 0.08),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Team Members:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  "Siddhant Galande, Ritika Chavan, Kaushik Gunavare, Purva Chaudhari, Prajwal Pawar",
                ),
                SizedBox(height: 8),
                Text("Project Status: Under Development"),
                Text("Deployment: Will be deployed online"),
              ],
            ),
          ),
          SizedBox(height: 24),
          // Logout Button
          Center(
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Confirm logout'),
                    content: Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Sign out'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await FirebaseAuth.instance.signOut();
                  // After sign out, clear navigation and go to login screen
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => LoginPage()),
                      (route) => false,
                    );
                  }
                }
              },
              icon: Icon(Icons.logout, color: Colors.white),
              label: Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnly(UserModel? userModel, User? authUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          userModel?.displayName ?? authUser?.displayName ?? 'User',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        if ((userModel?.location ?? authUser?.email) != null)
          Text(
            userModel?.location ?? authUser?.email ?? '',
            style: TextStyle(color: Colors.grey[700]),
          ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.verified, color: Colors.green, size: 18),
            SizedBox(width: 4),
            Text(
              "Trust Score: 4.8",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditForm(UserModel? userModel) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Full name'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter name' : null,
          ),
          SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(labelText: 'Phone'),
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              final cleaned = v.replaceAll(RegExp(r'[^0-9]'), '');
              return (cleaned.length < 7) ? 'Enter valid phone' : null;
            },
          ),
          SizedBox(height: 8),
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(labelText: 'Location / City'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter location' : null,
          ),
          SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: _saving ? null : () => _save(userModel),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: _saving
                    ? SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('Save'),
              ),
              SizedBox(width: 12),
              TextButton(
                onPressed: _saving
                    ? null
                    : () => setState(() => _editing = false),
                child: Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Quick Stats Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(255, 152, 0, 0.08),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.orange, size: 28),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
