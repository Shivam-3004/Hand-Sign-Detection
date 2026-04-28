import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notifications = true;
  bool haptics = true;
  bool autoDetect = true;

  double sensitivity = 75;
  double confidence = 85;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Settings",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Configure AI model & preferences",
                style: TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 30),

              /// GENERAL SECTION
              const Text(
                "GENERAL",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              _glassCard(
                children: [
                  _toggleTile(
                    title: "Notifications",
                    subtitle: "Detection alerts",
                    icon: Icons.notifications,
                    color: Colors.cyanAccent,
                    value: notifications,
                    onChanged: (val) {
                      setState(() => notifications = val);
                    },
                  ),
                  _divider(),
                  _toggleTile(
                    title: "Haptic Feedback",
                    subtitle: "Vibration on detection",
                    icon: Icons.flash_on,
                    color: Colors.purpleAccent,
                    value: haptics,
                    onChanged: (val) {
                      setState(() => haptics = val);
                    },
                  ),
                  _divider(),
                  _toggleTile(
                    title: "Auto Detection",
                    subtitle: "Start on camera open",
                    icon: Icons.visibility,
                    color: Colors.greenAccent,
                    value: autoDetect,
                    onChanged: (val) {
                      setState(() => autoDetect = val);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 30),

              /// AI MODEL SECTION
              const Text(
                "AI MODEL",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              _glassCard(
                children: [
                  _sliderTile(
                    title: "Sensitivity",
                    subtitle: "Detection responsiveness",
                    icon: Icons.tune,
                    color: Colors.cyanAccent,
                    value: sensitivity,
                    onChanged: (val) {
                      setState(() => sensitivity = val);
                    },
                  ),
                  _divider(),
                  _sliderTile(
                    title: "Confidence Threshold",
                    subtitle: "Minimum accuracy required",
                    icon: Icons.memory,
                    color: Colors.purpleAccent,
                    value: confidence,
                    onChanged: (val) {
                      setState(() => confidence = val);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 30),

              /// MODEL INFO CARD
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.cyanAccent.withOpacity(0.15),
                      Colors.purpleAccent.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.memory, color: Colors.cyanAccent, size: 30),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "YOLO v8 Model",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Real-time detection • 28 FPS average",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() {
    return const Divider(
      color: Colors.white10,
      height: 1,
    );
  }

  Widget _toggleTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: Colors.cyanAccent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _sliderTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double value,
    required Function(double) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${value.toInt()}%",
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Slider(
            value: value,
            min: 0,
            max: 100,
            activeColor: color,
            inactiveColor: Colors.white24,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
