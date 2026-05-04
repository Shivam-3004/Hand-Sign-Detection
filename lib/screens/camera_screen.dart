import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:handsingdetection/services/api_service.dart';
import 'package:handsingdetection/services/camera_service.dart';
import 'package:handsingdetection/theme/haptic_provider.dart';
import 'package:image/image.dart' as img;

import '../theme/app_theme.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  final CameraService _cameraService = CameraService();

  final String _userId = 'user_${DateTime.now().millisecondsSinceEpoch}';

  bool _isLoading = true;
  bool _isFrontCamera = true;
  bool _isFlashOn = false;
  bool _isSwitching = false;

  bool _isLive = false;
  bool _isSendingFrame = false;

  String? _prediction;
  String? _lastPrediction;

  bool _handVisible = false;
  bool _bufferReady = false;
  int _frameCount = 0;

  static const int _frameIntervalMs = 200;
  DateTime _lastFrameSent = DateTime(2000);

  int _fps = 0;
  int _fpsRawCount = 0;
  Timer? _fpsTimer;
  Timer? _webTimer;

  late AnimationController _switchAnimCtrl;
  late Animation<double> _switchRotAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initCamera();
  }

  void _setupAnimations() {
    _switchAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _switchRotAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_switchAnimCtrl);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(
      begin: 0.85,
      end: 1,
    ).animate(_pulseCtrl);
  }

  @override
  void dispose() {
    _fpsTimer?.cancel();
    _webTimer?.cancel();
    _cameraService.dispose();
    _switchAnimCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }



  Future<void> _initCamera() async {
    await _cameraService.initializeFrontCamera();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_isSwitching) return;

    _switchAnimCtrl.forward(from: 0);

    setState(() => _isSwitching = true);

    if (_isFrontCamera) {
      await _cameraService.initializeBackCamera();
    } else {
      await _cameraService.initializeFrontCamera();
    }

    if (mounted) {
      setState(() {
        _isFrontCamera = !_isFrontCamera;
        _isSwitching = false;
      });
    }
  }

  Future<void> _toggleFlash() async {
    if (_isFrontCamera) return;

    final newMode = _isFlashOn ? FlashMode.off : FlashMode.torch;

    await _cameraService.setFlashMode(newMode);

    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  Future<void> _toggleStream() async {
    _isLive ? await _stopStream() : await _startStream();
  }

  Future<void> _startStream() async {
    final healthy = await ApiService.checkServerHealth();

    if (!healthy) {
      _showSnack("Server unreachable");
      return;
    }

    setState(() {
      _isLive = true;
      _prediction = null;
      _fps = 0;
      _fpsRawCount = 0;
    });

    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _fps = _fpsRawCount;
          _fpsRawCount = 0;
        });
      }
    });

    if (kIsWeb) {
      _webTimer = Timer.periodic(
        const Duration(milliseconds: 1000),
            (_) => _captureAndSendWeb(),
      );
    } else {
      await _cameraService.startImageStream(_onCameraFrame);
    }
  }

  Future<void> _stopStream() async {
    _fpsTimer?.cancel();
    _webTimer?.cancel();

    if (!kIsWeb) {
      await _cameraService.stopImageStream();
    }

    setState(() {
      _isLive = false;
    });
  }

  Uint8List _convertToJpeg(CameraImage image) {
    final width = image.width;
    final height = image.height;

    final img.Image imgBuffer = img.Image(width: width, height: height);

    final plane = image.planes[0];

    // Fast grayscale conversion
    for (int i = 0; i < width * height; i++) {
      final pixel = plane.bytes[i];
      imgBuffer.setPixelRgb(i % width, i ~/ width, pixel, pixel, pixel);
    }

    // 🔥 Resize (MOST IMPORTANT)
    final resized = img.copyResize(imgBuffer, width: 224, height: 224);

    // 🔥 Compress
    return Uint8List.fromList(img.encodeJpg(resized, quality: 70));
  }

  Future<void> _onCameraFrame(Uint8List jpegBytes) async {

    // 🔥 MIRROR FIX (IMPORTANT)
    if (_isFrontCamera) {
      final original = img.decodeJpg(jpegBytes);
      if (original != null) {
        final flipped = img.flipHorizontal(original);
        jpegBytes = Uint8List.fromList(img.encodeJpg(flipped));
      }
    }

    final haptic = context.read<HapticProvider>();

    _fpsRawCount++;

    final now = DateTime.now();

    if (_isSendingFrame ||
        now.difference(_lastFrameSent).inMilliseconds < _frameIntervalMs) {
      return;
    }

    _lastFrameSent = now;
    _isSendingFrame = true;

    try {
      final result = await ApiService.predictFrame(
        jpegBytes: jpegBytes,
        userId: _userId,
      );

      if (mounted && result != null) {
        final newPrediction = result['prediction'];

        if (haptic.enabled &&
            newPrediction != null &&
            newPrediction != _lastPrediction) {
          HapticFeedback.mediumImpact();
        }

        _lastPrediction = newPrediction;

        setState(() {
          _prediction = newPrediction;
          _handVisible = result['hand_visible'] ?? false;
          _bufferReady = result['buffer_ready'] ?? false;
          _frameCount = result['frame_count'] ?? 0;
        });
      }
    } catch (e) {
      print("Frame error: $e");
    } finally {
      _isSendingFrame = false;
    }
  }

  Future<void> _captureAndSendWeb() async {
    if (_isSendingFrame) return;

    _isSendingFrame = true;

    final file = await _cameraService.captureImage();

    if (file == null) {
      _isSendingFrame = false;
      return;
    }

    final bytes = await file.readAsBytes();

    final result = await ApiService.predictFrame(
      jpegBytes: bytes,
      userId: _userId,
    );

    if (mounted && result != null) {
      setState(() {
        _prediction = result['prediction'];
      });
    }

    _isSendingFrame = false;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _cameraService.controller;

    if (_isLoading || ctrl == null || !ctrl.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: AspectRatio(
                aspectRatio: ctrl.value.aspectRatio,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: ctrl.value.previewSize!.height,
                    height: ctrl.value.previewSize!.width,
                    child: _isFrontCamera
                        ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
                      child: CameraPreview(ctrl),
                    )
                        : CameraPreview(ctrl),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 40,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      context.colors.bgCard.withOpacity(0.9),
                      context.colors.bgCard.withOpacity(0.6),
                    ],
                  ),
                  border: Border.all(
                    color: context.colors.border.withOpacity(0.6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: context.colors.textPrimary,
                ),
              ),
            ),
          ),

          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: _toggleFlash,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _isFlashOn
                        ? [
                      context.colors.accent,
                      context.colors.accent.withOpacity(0.7),
                    ]
                        : [
                      context.colors.bgCard.withOpacity(0.9),
                      context.colors.bgCard.withOpacity(0.6),
                    ],
                  ),
                  border: Border.all(
                    color: context.colors.border.withOpacity(0.6),
                  ),
                  boxShadow: _isFlashOn
                      ? [
                    BoxShadow(
                      color: context.colors.accent.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                      : [],
                ),
                child: Icon(
                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: _isFlashOn
                      ? Colors.white
                      : context.colors.textSecondary,
                  size: 22,
                ),
              ),
            ),
          ),

          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _prediction ?? "No detection",
                style: TextStyle(
                  color: _handVisible ? Colors.greenAccent : Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 50,
            left: 40,
            child: RotationTransition(
              turns: _switchRotAnim,
              child: GestureDetector(
                onTap: _switchCamera,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        context.colors.bgCard.withOpacity(0.9),
                        context.colors.bgCard.withOpacity(0.6),
                      ],
                    ),
                    border: Border.all(
                      color: context.colors.border.withOpacity(0.6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.isDark
                            ? Colors.black.withOpacity(0.4)
                            : Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.flip_camera_ios,
                    color: context.colors.textPrimary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 50,
            right: 40,
            child: ScaleTransition(
              scale: _isLive ? _pulseAnim : const AlwaysStoppedAnimation(1),
              child: GestureDetector(
                onTap: _toggleStream,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,

                    // 🔥 KEY FIX: Different style for light mode
                    color: !context.colors.isDark
                        ? (_isLive
                        ? context.colors.accent
                        : context.colors.bgCard)
                        : null,

                    gradient: context.colors.isDark
                        ? LinearGradient(
                      colors: _isLive
                          ? [
                        context.colors.accent,
                        context.colors.accent.withOpacity(0.7),
                      ]
                          : [
                        context.colors.gradStart,
                        context.colors.gradEnd,
                      ],
                    )
                        : null,

                    border: !context.colors.isDark
                        ? Border.all(
                      color: context.colors.border.withOpacity(0.6),
                    )
                        : null,

                    boxShadow: [
                      BoxShadow(
                        color: _isLive
                            ? context.colors.accent.withOpacity(0.35)
                            : Colors.black.withOpacity(
                          context.colors.isDark ? 0.4 : 0.15,
                        ),
                        blurRadius: _isLive ? 18 : 10,
                        spreadRadius: _isLive ? 2 : 0,
                      ),
                    ],
                  ),

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isLive
                            ? Icons.sensors_off_rounded
                            : Icons.sensors_rounded,
                        color: context.colors.isDark
                            ? Colors.white
                            : (_isLive
                            ? Colors.white
                            : context.colors.textPrimary),
                        size: 26,
                      ),
                      Text(
                        _isLive ? "LIVE" : "START",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: context.colors.isDark
                              ? Colors.white
                              : (_isLive
                              ? Colors.white
                              : context.colors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),


          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                _isLive ? "LIVE • $_fps fps" : "GESTURE AI",
                style: TextStyle(
                  color: _isLive ? Colors.redAccent : Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}