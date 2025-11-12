import 'package:flutter/material.dart';
import '../models/user_model.dart';

class HeaderWidget extends StatelessWidget {
  final UserModel? userModel;

  const HeaderWidget({super.key, this.userModel});

  @override
  Widget build(BuildContext context) {
    final name = userModel?.displayName != null
        ? userModel!.displayName!.split(' ').first
        : 'there';
    final location = userModel?.location ?? 'Nashik';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hi $name!', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Finding your drive in ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(width: 6),
                GestureDetector(
                  onTap: () {},
                  child: Row(
                    children: [
                      Text(
                        location,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.secondary,
                Theme.of(context).colorScheme.primary,
              ],
            ),
            shape: BoxShape.circle,
          ),
          padding: EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Colors.transparent,
            child: Icon(Icons.monetization_on, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
