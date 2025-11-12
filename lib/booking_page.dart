import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/car_model.dart';
import 'models/user_model.dart';
import 'services/trip_service.dart';
import 'my_trips.dart';

class BookingPage extends StatefulWidget {
  final CarModel car;
  final UserModel? userModel;

  const BookingPage({super.key, required this.car, this.userModel});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _booking = false;
  final TripService _tripService = TripService();

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEnd() async {
    final start = _startDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: start.add(Duration(days: 1)),
      firstDate: start,
      lastDate: DateTime(start.year + 1),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _book() async {
    if (widget.userModel == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please sign in to book')));
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Select start and end dates')));
      return;
    }
    if (!_endDate!.isAfter(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('End date must be after start date')),
      );
      return;
    }

    setState(() => _booking = true);
    try {
      final startTs = Timestamp.fromDate(_startDate!);
      final endTs = Timestamp.fromDate(_endDate!);
      final dateStr =
          '${_startDate!.toLocal().toString().split(' ')[0]} - ${_endDate!.toLocal().toString().split(' ')[0]}';
      final data = {
        'userId': widget.userModel!.uid,
        'carId': widget.car.id,
        'carName': widget.car.name,
        'location': widget.car.location,
        'startAt': startTs,
        'endAt': endTs,
        'date': dateStr,
        'status': 'Upcoming',
        'createdAt': FieldValue.serverTimestamp(),
      };
      await _tripService.createTrip(data);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Booking created')));
        // Navigate user to My Trips so they can immediately see their booking
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => MyTripsPage()));
      }
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Booking failed: $e')));
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  int _estimateTotal() {
    if (_startDate == null || _endDate == null) return widget.car.pricePerDay;
    final days = _endDate!.difference(_startDate!).inDays;
    final safeDays = days > 0 ? days : 1;
    return widget.car.pricePerDay * safeDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Book ${widget.car.name}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.car.name,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(widget.car.location),
            SizedBox(height: 16),
            Text(
              'Select booking dates',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _pickStart,
                    child: Text(
                      _startDate == null
                          ? 'Start date'
                          : _startDate!.toLocal().toString().split(' ')[0],
                    ),
                    style: ElevatedButton.styleFrom(),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _pickEnd,
                    child: Text(
                      _endDate == null
                          ? 'End date'
                          : _endDate!.toLocal().toString().split(' ')[0],
                    ),
                    style: ElevatedButton.styleFrom(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Text(
              'Price: ₹${widget.car.pricePerDay}/day',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              _startDate != null && _endDate != null
                  ? 'Estimated total: ₹${_estimateTotal()}'
                  : 'Select dates to see estimate',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _booking ? null : _book,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
                child: _booking
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Book now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
