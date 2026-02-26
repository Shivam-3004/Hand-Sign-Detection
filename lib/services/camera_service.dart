import 'package:camera/camera.dart';

/// Simple helper that initialises the first available camera and keeps a
/// reference to a [CameraController].
///
/// Consumers are responsible for calling [dispose].
class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _availableCameras;

  /// Initialise the camera (must be called before accessing [controller]).
  Future<void> initialize() async {
    _availableCameras = await availableCameras();
    if (_availableCameras!.isNotEmpty) {
      _controller =
          CameraController(_availableCameras!.first, ResolutionPreset.medium);
      await _controller!.initialize();
    }
  }

  CameraController? get controller => _controller;

  /// Captures a still image and returns the resulting [XFile].
  Future<XFile?> takePicture() async {
    if (_controller != null && _controller!.value.isInitialized) {
      return await _controller!.takePicture();
    }
    return null;
  }

  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}
