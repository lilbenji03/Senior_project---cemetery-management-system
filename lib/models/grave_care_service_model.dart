// lib/models/grave_care_service_model.dart

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
  final String estimatedCostRange; // e.g., "$90 - $300", "From $50 + flowers"
  final String?
  moreInfoLink; // Optional link to an external provider or info page
  final String?
  providerExample; // e.g., "gravecareservices.com", "Heaven's Maid"
  final String? contactPhoneNumber; // <--- ADDED THIS FIELD

  GraveCareService({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.estimatedCostRange,
    this.moreInfoLink,
    this.providerExample,
    this.contactPhoneNumber, // <--- ADDED TO CONSTRUCTOR
  });
}

// Sample Data for GraveCareService
List<GraveCareService> sampleGraveCareServices = [
  GraveCareService(
    id: 'GC001',
    name: 'Standard Grave Cleaning',
    type: GraveCareServiceType.cleaning,
    description:
        'Cleaning of headstone, removal of debris, and general upkeep of the grave area.',
    estimatedCostRange: 'KES 9,000 - KES 30,000',
    providerExample: 'Local professionals',
    contactPhoneNumber: '+254 700 123 456', // Example Kenyan phone number
  ),
  GraveCareService(
    id: 'GC002',
    name: 'Floral Arrangement Placement',
    type: GraveCareServiceType.floral,
    description:
        'Placement of fresh or artificial flowers on the grave. Cost of flowers usually separate.',
    estimatedCostRange: 'Approx. KES 5,000 (service fee)',
    providerExample: 'gravecareservices.com (example)',
    contactPhoneNumber: '+254 711 987 654', // Example Kenyan phone number
  ),
  GraveCareService(
    id: 'GC003',
    name: 'Headstone & Memorial Construction',
    type: GraveCareServiceType.construction,
    description:
        'Building or renovating grave structures, erecting headstones, or constructing grave surrounds. Quotes provided upon inquiry.',
    estimatedCostRange: 'Varies (Request Quote)',
    providerExample: 'Local service providers',
    // No phone number for this example, to test conditional display
  ),
  GraveCareService(
    id: 'GC004',
    name: 'Online Memorial Page Creation',
    type: GraveCareServiceType.memorialPage,
    description:
        'Creation of an online memorial page with photos, biography, and messages.',
    estimatedCostRange: 'Varies by features',
    providerExample: "Heaven's Maid (example)",
    moreInfoLink: 'https://example.com/memorialpageinfo',
    contactPhoneNumber: '+254 722 111 222', // Example Kenyan phone number
  ),
  GraveCareService(
    id: 'GC005',
    name: 'Scheduled Maintenance Plan (3 Visits/Year)',
    type: GraveCareServiceType.maintenancePlan,
    description:
        'Ensures the gravesite remains in good condition with 3 scheduled visits per year for cleaning and upkeep.',
    estimatedCostRange: 'Approx. KES 15,000 per year',
    providerExample: 'Various providers',
    contactPhoneNumber: '+254 733 555 888', // Example Kenyan phone number
  ),
];
