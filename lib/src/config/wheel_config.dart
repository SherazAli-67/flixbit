import 'package:flixbit/src/config/wheel_segment.dart';
import 'package:flutter/material.dart';

// Default wheel configuration
class WheelConfig {
  static List<WheelSegment> defaultSegments = [
    WheelSegment(
      label: '150%',
      multiplier: 1.5,
      probability: 5,
      color: Color(0xFFFFD700), // Gold
    ),
    WheelSegment(
      label: '25%',
      multiplier: 0.25,
      probability: 15,
      color: Color(0xFFFF6B6B), // Red
    ),
    WheelSegment(
      label: '120%',
      multiplier: 1.2,
      probability: 10,
      color: Color(0xFF4ECDC4), // Teal
    ),
    WheelSegment(
      label: '50%',
      multiplier: 0.5,
      probability: 20,
      color: Color(0xFFFF8B94), // Pink
    ),
    WheelSegment(
      label: '100%',
      multiplier: 1.0,
      probability: 25,
      color: Color(0xFF95E1D3), // Light green
    ),
    WheelSegment(
      label: '80%',
      multiplier: 0.8,
      probability: 25,
      color: Color(0xFFFFA07A), // Light orange
    ),
  ];
}