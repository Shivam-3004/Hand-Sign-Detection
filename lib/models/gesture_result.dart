class GestureResult {
  final String label;
  final double confidence;

  GestureResult({required this.label, required this.confidence});

  factory GestureResult.fromJson(Map<String, dynamic> json) {
    return GestureResult(
      label: json['label'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  @override
  String toString() => '$label (${(confidence * 100).toStringAsFixed(1)}%)';
}
