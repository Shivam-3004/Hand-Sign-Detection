import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  CameraDescription? _currentCamera;

  int _frameCount = 0;

  CameraController? get controller => _controller;
  CameraDescription? get currentCamera => _currentCamera;

  bool get isCameraInitialized =>
      _controller != null && _controller!.value.isInitialized;

  bool get isFrontCamera =>
      _currentCamera?.lensDirection == CameraLensDirection.front;

  bool get isStreamingImages =>
      _controller?.value.isStreamingImages ?? false;

  // ─────────────────────────────
  // Fetch cameras
  // ─────────────────────────────
  Future<void> _fetchCameras() async {
    if (_cameras.isEmpty) {
      _cameras = await availableCameras();
    }
  }

  // ─────────────────────────────
  // Init camera
  // ─────────────────────────────
  Future<void> _initWith(CameraDescription description) async {
    if (_controller != null) {
      if (!kIsWeb && _controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
      await _controller!.dispose();
      _controller = null;
    }

    _currentCamera = description;

    _controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();
  }

  Future<void> initializeFrontCamera() async {
    await _fetchCameras();
    final cam = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first,
    );
    await _initWith(cam);
  }

  Future<void> initializeBackCamera() async {
    await _fetchCameras();
    final cam = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );
    await _initWith(cam);
  }

  // ─────────────────────────────
  // START STREAM (JPEG output)
  // ─────────────────────────────
  Future<void> startImageStream(
      Future<void> Function(Uint8List jpegBytes) onFrame) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_controller!.value.isStreamingImages) return;

    await _controller!.startImageStream((CameraImage image) async {
      _frameCount++;

      if (_frameCount % 5 != 0) return; // skip frames

      try {
        final jpeg = _convertToJpeg(image);
        await onFrame(jpeg);
      } catch (e) {
        print("Frame error: $e");
      }
    });
  }

  // ─────────────────────────────
  // FIXED JPEG conversion
  // ─────────────────────────────
  Uint8List _convertToJpeg(CameraImage image) {
    final width = image.width;
    final height = image.height;

    final img.Image imgBuffer = img.Image(width: width, height: height);
    final plane = image.planes[0];

    for (int i = 0; i < width * height; i++) {
      final pixel = plane.bytes[i];

      final x = i % width;
      final y = i ~/ width;

      // ✅ FIX (no getColor, no data[])
      imgBuffer.setPixelRgb(x, y, pixel, pixel, pixel);
    }

    final resized = img.copyResize(imgBuffer, width: 224, height: 224);

    return Uint8List.fromList(img.encodeJpg(resized, quality: 70));
  }

  // ─────────────────────────────
  // EXTRA FUNCTIONS (fix errors)
  // ─────────────────────────────

  Future<XFile?> captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) return null;

    try {
      return await _controller!.takePicture();
    } catch (e) {
      print("capture error: $e");
      return null;
    }
  }

  Future<void> setFlashMode(FlashMode mode) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      await _controller!.setFlashMode(mode);
    } catch (e) {
      print("flash error: $e");
    }
  }

  Future<void> stopImageStream() async {
    if (_controller != null && _controller!.value.isStreamingImages) {
      await _controller!.stopImageStream();
    }
  }

  Future<void> dispose() async {
    if (_controller != null) {
      await stopImageStream();
      await _controller!.dispose();
      _controller = null;
    }
  }
}