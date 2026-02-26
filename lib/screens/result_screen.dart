import 'package:flutter/material.dart';

import '../models/gesture_result.dart';
import '../services/tts_service.dart';

class ResultScreen extends StatelessWidget {
  final GestureResult result;

  const ResultScreen({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // speak when the screen builds
    Future.microtask(() => TtsService().speak(result.label));

    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(result.label, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text('Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
