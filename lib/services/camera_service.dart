import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;

  CameraController? get controller => _controller;
  List<CameraDescription>? get cameras => _cameras;
  bool get isCameraInitialized => _controller != null && _controller!.value.isInitialized;

  /// Initializes available cameras
  Future<List<CameraDescription>> initializeCameras() async {
    try {
      _cameras = await availableCameras();
      return _cameras ?? [];
    } catch (e) {
      throw Exception('Error initializing cameras: $e');
    }
  }

  /// Selects and initializes a camera
  Future<void> selectCamera(CameraDescription camera) async {
    try {
      await _controller?.dispose();

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      debugPrint('Camera initialized successfully');
    } catch (e) {
      throw Exception('Error selecting camera: $e');
    }
  }

  /// Captures a photo and returns the file path
  Future<XFile?> takePicture() async {
    try {
      if (!isCameraInitialized) {
        throw Exception('Camera is not initialized');
      }

      final image = await _controller!.takePicture();
      return image;
    } catch (e) {
      throw Exception('Error taking picture: $e');
    }
  }

  /// Gets the front camera for gesture detection
  Future<void> initializeFrontCamera() async {
    try {
      await initializeCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras available');
      }

      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      await selectCamera(frontCamera);
    } catch (e) {
      throw Exception('Error initializing front camera: $e');
    }
  }

  /// Starts the camera preview
  Future<void> startCameraPreview() async {
    try {
      if (!isCameraInitialized) {
        throw Exception('Camera is not initialized');
      }
      // Preview starts automatically after initialization
      debugPrint('Camera preview started');
    } catch (e) {
      throw Exception('Error starting camera preview: $e');
    }
  }

  /// Stops the camera preview
  Future<void> stopCameraPreview() async {
    try {
      if (_controller != null && isCameraInitialized) {
        // Preview stops when camera is disposed
        debugPrint('Camera preview stopped');
      }
    } catch (e) {
      throw Exception('Error stopping camera preview: $e');
    }
  }

  /// Sets the flash mode
  Future<void> setFlashMode(FlashMode mode) async {
    try {
      if (!isCameraInitialized) {
        throw Exception('Camera is not initialized');
      }
      await _controller!.setFlashMode(mode);
    } catch (e) {
      throw Exception('Error setting flash mode: $e');
    }
  }

  /// Zooms the camera
  Future<void> setZoom(double zoom) async {
    try {
      if (!isCameraInitialized) {
        throw Exception('Camera is not initialized');
      }
      await _controller!.setZoomLevel(zoom);
    } catch (e) {
      throw Exception('Error setting zoom: $e');
    }
  }

  /// Disposes the camera controller
  Future<void> dispose() async {
    try {
      await _controller?.dispose();
      _controller = null;
      debugPrint('Camera disposed');
    } catch (e) {
      debugPrint('Error disposing camera: $e');
    }
  }
}
