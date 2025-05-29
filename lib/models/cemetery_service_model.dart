// lib/models/cemetery_service_model.dart
class CemeteryService {
  final String id;
  final String name;
  final double cost;
  bool isSelected; // To track selection by user

  CemeteryService({
    required this.id,
    required this.name,
    required this.cost,
    this.isSelected = false,
  });
}

// Sample services - in a real app, these might be specific to a cemetery
List<CemeteryService> getSampleCemeteryServices() {
  return [
    CemeteryService(id: 'S001', name: 'Standard Tent Setup', cost: 5000.00),
    CemeteryService(
        id: 'S002', name: 'Plastic Chairs (Set of 20)', cost: 1500.00),
    CemeteryService(id: 'S003', name: 'PA System', cost: 3000.00),
    CemeteryService(
        id: 'S004', name: 'Floral Arrangements (Basic)', cost: 2500.00),
  ];
}
