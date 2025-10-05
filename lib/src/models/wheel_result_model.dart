class WheelResult {
  final int segmentIndex;
  final double multiplier; // e.g., 0.5, 1.0, 1.5
  final double finalAmount;

  WheelResult({
    required this.segmentIndex,
    required this.multiplier,
    required this.finalAmount,
  });

  factory WheelResult.fromJson(Map<String, dynamic> json) {
    return WheelResult(
      segmentIndex: json['segment_index'],
      multiplier: json['multiplier'].toDouble(),
      finalAmount: json['final_amount'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'segment_index': segmentIndex,
      'multiplier': multiplier,
      'final_amount': finalAmount,
    };
  }
}
