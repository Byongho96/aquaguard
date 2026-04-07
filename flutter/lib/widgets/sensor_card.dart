import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class SensorCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String unit;
  final bool isAlert;

  const SensorCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    this.isAlert = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color iconAndTitleColor = Colors.white70;
    const Color valueColor = Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: isAlert ? const Color(0xFF2F2F2F) : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconAndTitleColor, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: iconAndTitleColor, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                unit,
                style: TextStyle(color: iconAndTitleColor, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
