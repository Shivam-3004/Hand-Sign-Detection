import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/gesture_result.dart';
import '../services/api_service.dart';
import '../services/camera_service.dart';
import 'result_screen.dart';

/// Example camera page which takes a picture and sends it to the API.
class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final CameraService _cameraService = CameraService();
  bool _initialised = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    await _cameraService.initialize();
    if (mounted) {
      setState(() {
        _initialised = true;
      });
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  Future<void> _captureAndClassify() async {
    final XFile? file = await _cameraService.takePicture();
    if (file == null) return;

    setState(() => _sending = true);
    try {
      final api = ApiService(baseUrl: 'https://example.com'); // adjust
      final GestureResult result =
          await api.classifyImage(File(file.path));
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResultScreen(result: result),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialised) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final controller = _cameraService.controller!;

    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: Stack(
        children: [
          CameraPreview(controller),
          if (_sending)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sending ? null : _captureAndClassify,
        child: const Icon(Icons.camera),
      ),
    );
  }
}
