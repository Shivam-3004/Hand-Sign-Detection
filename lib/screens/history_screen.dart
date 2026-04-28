import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyItems = [
      {
        "gesture": "Open Palm",
        "action": "Play/Pause",
        "confidence": 0.968,
        "time": "2 min ago",
        "color": Colors.cyanAccent,
        "icon": Icons.pan_tool,
      },
      {
        "gesture": "Thumbs Up",
        "action": "Volume Up",
        "confidence": 0.942,
        "time": "5 min ago",
        "color": Colors.greenAccent,
        "icon": Icons.thumb_up,
      },
      {
        "gesture": "Fist",
        "action": "Stop",
        "confidence": 0.915,
        "time": "8 min ago",
        "color": Colors.purpleAccent,
        "icon": Icons.back_hand,
      },
      {
        "gesture": "Swipe Right",
        "action": "Next",
        "confidence": 0.893,
        "time": "12 min ago",
        "color": Colors.blueAccent,
        "icon": Icons.swipe,
      },
      {
        "gesture": "Peace Sign",
        "action": "Screenshot",
        "confidence": 0.871,
        "time": "15 min ago",
        "color": Colors.pinkAccent,
        "icon": Icons.pan_tool_alt,
      },
    ];

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Detection History",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Recent gesture detections",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),

              /// Scrollable Timeline
              Expanded(
                child: ListView.builder(
                  itemCount: historyItems.length + 1,
                  itemBuilder: (context, index) {
                    if (index == historyItems.length) {
                      return _buildEndMarker();
                    }

                    final item = historyItems[index];
                    final color = item["color"] as Color;
                    final confidence = item["confidence"] as double;

                    return Stack(
                      children: [
                        /// Timeline line
                        if (index != historyItems.length - 1)
                          Positioned(
                            left: 32,
                            top: 60,
                            bottom: -10,
                            child: Container(
                              width: 2,
                              color: Colors.cyanAccent.withOpacity(0.3),
                            ),
                          ),

                        /// Card
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// Icon
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: color.withOpacity(0.5)),
                                ),
                                child: Icon(
                                  item["icon"] as IconData,
                                  color: color,
                                  size: 20,
                                ),
                              ),

                              const SizedBox(width: 16),

                              /// Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item["gesture"] as String,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item["action"] as String,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              "${(confidence * 100).toStringAsFixed(1)}%",
                                              style: TextStyle(
                                                color: color,
                                                fontWeight:
                                                FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item["time"] as String,
                                              style: const TextStyle(
                                                color: Colors.white38,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 10),

                                    /// Confidence Bar
                                    ClipRRect(
                                      borderRadius:
                                      BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: confidence,
                                        backgroundColor:
                                        Colors.white10,
                                        valueColor:
                                        AlwaysStoppedAnimation(color),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEndMarker() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: const [
          Icon(Icons.flash_off,
              color: Colors.white38, size: 18),
          SizedBox(width: 10),
          Text(
            "End of history",
            style: TextStyle(color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
