import 'package:flutter/material.dart';

class WheelSegment {
  final String label;
  final double multiplier;
  final int probability; // Weight for random selection
  final Color color;

  const WheelSegment({
    required this.label,
    required this.multiplier,
    required this.probability,
    required this.color,
  });

  // Helper method to format display text
  String get displayLabel => label;

  // Helper to get percentage as string
  String get percentageLabel => '${(multiplier * 100).toInt()}%';

  // Check if this is a winning segment (more than 100%)
  bool get isWinning => multiplier > 1.0;

  // Check if this is a losing segment (less than 100%)
  bool get isLosing => multiplier < 1.0;

  // Check if this is break-even (exactly 100%)
  bool get isBreakEven => multiplier == 1.0;
}