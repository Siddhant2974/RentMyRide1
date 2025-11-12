import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/user_model.dart';
import 'models/car_model.dart';
import 'services/car_service.dart';
import 'package:image_picker/image_picker.dart';

class HostEarnPage extends StatefulWidget {
  final String? hostIdParam;

  const HostEarnPage({super.key, this.hostIdParam});

  @override
  State<HostEarnPage> createState() => _HostEarnPageState();
}

class _HostEarnPageState extends State<HostEarnPage> {
  final CarService _carService = CarService();
  bool _adding = false;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String? _photoUrl;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(String hostId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      final url = await _carService.uploadCarPhotoBytes(hostId, bytes);
      setState(() => _photoUrl = url);
    } else {
      final file = File(picked.path);
      final url = await _carService.uploadCarPhoto(hostId, file);
      setState(() => _photoUrl = url);
    }
  }

  Future<void> _createListing(String hostId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _adding = true);
    final car = CarModel(
      id: '',
      hostId: hostId,
      name: _nameCtrl.text.trim(),
      location: _locCtrl.text.trim(),
      pricePerDay: int.tryParse(_priceCtrl.text.trim()) ?? 0,
      photos: _photoUrl != null ? [_photoUrl!] : [],
      createdAt: DateTime.now(),
    );
    try {
      await _carService.createCar(car);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Listing created')));
      }
      _nameCtrl.clear();
      _locCtrl.clear();
      _priceCtrl.clear();
      setState(() {
        _photoUrl = null;
        _adding = false;
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Create failed: $e')));
      setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    // prefer explicit hostIdParam when provided (e.g. opened from Profile)
    final hostId = widget.hostIdParam ?? (user?.uid ?? '');

    return Scaffold(
      appBar: AppBar(title: Text('Host & Earn'), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user != null && user.isHost
                  ? 'Welcome back, ${user.displayName ?? 'Host'}'
                  : 'Welcome to your Host dashboard',
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
                          user != null ? '₹${user.walletBalance}' : '—',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: _buildAddForm(hostId),
                        ),
                      ),
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
            // Only query and show host listings when we have a valid hostId (user signed in)
            if (hostId.isEmpty)
              Expanded(
                child: Center(child: Text('Sign in to manage your listings')),
              )
            else
              Expanded(
                child: StreamBuilder<List<CarModel>>(
                  stream: _carService.streamCarsByHost(hostId),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting)
                      return Center(child: CircularProgressIndicator());
                    if (snap.hasError)
                      return Center(
                        child: Text('Error loading listings: ${snap.error}'),
                      );
                    final cars = snap.data ?? [];
                    if (cars.isEmpty)
                      return Center(child: Text('No listings yet'));
                    return ListView.separated(
                      itemCount: cars.length,
                      separatorBuilder: (_, __) => Divider(),
                      itemBuilder: (context, index) {
                        final car = cars[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange,
                            backgroundImage: car.photos.isNotEmpty
                                ? NetworkImage(car.photos.first)
                                : null,
                            child: car.photos.isEmpty
                                ? Icon(
                                    Icons.directions_car,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          title: Text(car.name),
                          subtitle: Text(
                            '₹${car.pricePerDay}/day • ${car.location}',
                          ),
                          trailing: Icon(Icons.chevron_right),
                          onTap: () {},
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddForm(String hostId) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add car listing',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(labelText: 'Car name'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter name' : null,
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _locCtrl,
                  decoration: InputDecoration(labelText: 'Location'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter location' : null,
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _priceCtrl,
                  decoration: InputDecoration(labelText: 'Price per day'),
                  keyboardType: TextInputType.number,
                  validator: (v) => int.tryParse(v ?? '') == null
                      ? 'Enter valid price'
                      : null,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickPhoto(hostId),
                      icon: Icon(Icons.camera_alt),
                      label: Text('Pick photo'),
                    ),
                    SizedBox(width: 12),
                    if (_photoUrl != null) Expanded(child: Text('Photo ready')),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _adding
                            ? null
                            : () => _createListing(hostId),
                        child: _adding
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text('Create'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
