import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _rotateController;
  late AnimationController _dotController;

  @override
  void initState() {
    super.initState();

    _floatController =
    AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);

    _rotateController =
    AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();

    _dotController =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();

    // Auto navigate after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _rotateController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A0A1F),
              Color(0xFF1A0F2E),
              Color(0xFF0F1729),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// Floating Animated Hand Icon
              AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                        0, -15 * _floatController.value),
                    child: child,
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    /// Glow Effects
                    Container(
                      width: 200,
                      height: 200,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.cyanAccent,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    /// Rotating Ring 1
                    AnimatedBuilder(
                      animation: _rotateController,
                      builder: (_, child) {
                        return Transform.rotate(
                          angle: _rotateController.value * 6.28,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.cyanAccent.withOpacity(0.4),
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    /// Rotating Ring 2
                    AnimatedBuilder(
                      animation: _rotateController,
                      builder: (_, child) {
                        return Transform.rotate(
                          angle: -_rotateController.value * 6.28,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                            Colors.purpleAccent.withOpacity(0.4),
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    /// Icon Container
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.cyanAccent.withOpacity(0.2),
                            Colors.purpleAccent.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.cyanAccent.withOpacity(0.4),
                        ),
                      ),
                      child: const Icon(
                        Icons.pan_tool,
                        size: 80,
                        color: Colors.cyanAccent,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              /// App Name
              const Text(
                "GestureAI",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Control with Gestures",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.cyanAccent,
                ),
              ),

              const SizedBox(height: 40),

              /// Loading Dots
              AnimatedBuilder(
                animation: _dotController,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      double delay = index * 0.3;
                      double value =
                      (_dotController.value - delay).clamp(0.0, 1.0);
                      return Container(
                        margin:
                        const EdgeInsets.symmetric(horizontal: 4),
                        width: 10 + (value * 6),
                        height: 10 + (value * 6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.cyanAccent,
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
