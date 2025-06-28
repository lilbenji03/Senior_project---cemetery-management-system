// In lib/models/cemetery_service_model.dart

class CemeteryService {
  final String id;
  final String name;
  final double cost;
  bool isSelected;

  CemeteryService({
    required this.id,
    required this.name,
    required this.cost,
    this.isSelected = false,
  });

  // CORRECTED: The 'async' keyword is removed.
  factory CemeteryService.fromJson(Map<String, dynamic> json) {
    return CemeteryService(
      // Use '??' to provide default values for safety
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Service',
      // Ensure cost is handled safely
      cost: (json['cost'] as num? ?? 0).toDouble(),
    );
  }
}
