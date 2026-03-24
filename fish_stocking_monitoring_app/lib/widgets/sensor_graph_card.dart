import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class SensorGraphCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final bool isAlert;
  final List<double> historyData;
  final VoidCallback onTap;

  final double minThreshold;
  final double maxThreshold;

  const SensorGraphCard({
    Key? key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.historyData,
    required this.onTap,
    this.isAlert = false,
    required this.minThreshold,
    required this.maxThreshold,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double range = maxThreshold - minThreshold;
    final double axisPadding = range == 0 ? 5.0 : range * 0.2;

    double chartMinY = minThreshold - axisPadding;
    double chartMaxY = maxThreshold + axisPadding;

    if (historyData.isNotEmpty) {
      final double minimumValue = historyData.reduce(min);
      final double maximumValue = historyData.reduce(max);

      if (minimumValue < chartMinY) {
        chartMinY = minimumValue - (axisPadding / 2);
      }
      if (maximumValue > chartMaxY) {
        chartMaxY = maximumValue + (axisPadding / 2);
      }
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isAlert ? const Color(0xFFE5533D) : AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              if (historyData.isNotEmpty)
                Positioned.fill(
                  top: 60,
                  child: LineChart(
                    LineChartData(
                      minY: chartMinY,
                      maxY: chartMaxY,
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: historyData
                              .asMap()
                              .entries
                              .map(
                                (entry) =>
                                    FlSpot(entry.key.toDouble(), entry.value),
                              )
                              .toList(),
                          isCurved: true,
                          color: isAlert
                              ? Colors.white.withOpacity(0.8)
                              : Colors.white.withOpacity(0.3),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: isAlert
                                ? Colors.white.withOpacity(0.3)
                                : Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          unit,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(icon, color: Colors.white, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
