import 'package:flutter/material.dart';

class AppSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;

  const AppSearchBar({
    super.key,
    this.hint = 'Search car or location',
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Search cars or locations',
      textField: true,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.primary,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
          ),
        ),
      ),
    );
  }
}
