import 'dart:ui';
import 'package:flutter/material.dart';

class BottomNavigationAI extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigationAI({
    super.key,
    required this.currentIndex,
    required this.onTap, required String currentScreen, required Null Function(String p1) onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final navItems = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.history_rounded, 'label': 'History'},
      {'icon': Icons.settings_rounded, 'label': 'Settings'},
    ];

    return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navItems.length, (index) {
                final isActive = currentIndex == index;

                return GestureDetector(
                  onTap: () => onTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 16),
                    decoration: isActive
                        ? BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF00FFFF),
                          Color(0xFF6A5ACD),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    )
                        : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          navItems[index]['icon'] as IconData,
                          size: 22,
                          color: isActive
                              ? const Color(0xFF00FFFF)
                              : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          navItems[index]['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isActive
                                ? const Color(0xFF00FFFF)
                                : Colors.grey.shade400,
                          ),
                        ),
                        if (isActive)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00FFFF),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
    );
  }
}
