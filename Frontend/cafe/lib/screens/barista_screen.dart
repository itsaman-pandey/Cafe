import 'package:flutter/material.dart';

class BaristaScreen extends StatelessWidget {
  const BaristaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Barista View")),
      body: const Center(
        child: Text("View and prepare orders here", style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
