import 'package:flutter/material.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title Screen\n(Development Placeholder)',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.5),
        ),
      ),
    );
  }
}
