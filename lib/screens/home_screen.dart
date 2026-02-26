import 'package:flutter/material.dart';

import 'camera_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hand Sign Detection')),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.camera_alt),
          label: const Text('Start Camera'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CameraScreen()),
            );
          },
        ),
      ),
    );
  }
}