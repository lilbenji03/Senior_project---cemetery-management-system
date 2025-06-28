// lib/models/grave_care_service_model.dart
import 'package:flutter/material.dart';

enum GraveCareServiceType {
  cleaning,
  floral,
  construction,
  memorialPage,
  maintenancePlan,
}

class GraveCareService {
  final String id;
  final String name;
  final GraveCareServiceType type;
  final String description;
  final String estimatedCostRange;
  final String? providerExample;
  final String? contactPhoneNumber;

  GraveCareService({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.estimatedCostRange,
    this.providerExample,
    this.contactPhoneNumber,
  });

  // Helper getter for UI icons
  IconData get icon {
    switch (type) {
      case GraveCareServiceType.cleaning:
        return Icons.cleaning_services_rounded;
      case GraveCareServiceType.floral:
        return Icons.local_florist_rounded;
      case GraveCareServiceType.construction:
        return Icons.construction_rounded;
      case GraveCareServiceType.memorialPage:
        return Icons.public_rounded;
      case GraveCareServiceType.maintenancePlan:
        return Icons.event_repeat_rounded;
    }
  }
}

// Sample Data
List<GraveCareService> sampleGraveCareServices = [
  GraveCareService(
    id: 'GC001',
    name: 'Standard Grave Cleaning',
    type: GraveCareServiceType.cleaning,
    description:
        'Comprehensive cleaning of the headstone and grave area, including removal of debris, weeds, and gentle washing of the stone.',
    estimatedCostRange: 'KES 9,000 - 30,000',
    providerExample: 'Local Professionals',
    contactPhoneNumber: '+254700123456',
  ),
  GraveCareService(
    id: 'GC002',
    name: 'Floral Arrangement Service',
    type: GraveCareServiceType.floral,
    description:
        'Placement of fresh or high-quality artificial flowers on the grave. The cost of flowers is typically separate from the service fee.',
    estimatedCostRange: 'Service from KES 5,000',
    providerExample: 'Eternal Blooms',
    contactPhoneNumber: '+254711987654',
  ),
  GraveCareService(
    id: 'GC003',
    name: 'Memorial Construction',
    type: GraveCareServiceType.construction,
    description:
        'Includes headstone erection, grave surrounds (curbs), and memorial renovations. Quotes are provided upon site visit and inquiry.',
    estimatedCostRange: 'Varies',
    providerExample: 'Local Stonemasons',
    contactPhoneNumber: '+254722333444',
  ),
  GraveCareService(
    id: 'GC004',
    name: 'Annual Maintenance Plan',
    type: GraveCareServiceType.maintenancePlan,
    description:
        'Ensure the gravesite remains pristine. Includes 3-4 scheduled visits per year for full cleaning, weeding, and basic upkeep.',
    estimatedCostRange: 'Approx. KES 15,000/year',
    providerExample: 'Various Providers',
    contactPhoneNumber: '+254733555888',
  ),
  GraveCareService(
    id: 'GC005',
    name: 'Online Memorial Page',
    type: GraveCareServiceType.memorialPage,
    description:
        'A beautiful, permanent online page to share memories, photos, and a biography of your loved one with family and friends.',
    estimatedCostRange: 'From KES 10,000',
    providerExample: "Legacy Pages",
    contactPhoneNumber: '+254733555887',
  ),
];
