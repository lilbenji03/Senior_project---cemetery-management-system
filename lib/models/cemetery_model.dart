// lib/models/cemetery_model.dart
class Cemetery {
  final String id;
  final String name;
  final int availableSpots;
  final int totalSpots;
  final String imageUrl;
  final String? locationDescription;
  final double? latitude; // <--- ADD/ENSURE THIS
  final double? longitude; // <--- ADD/ENSURE THIS

  Cemetery({
    required this.id,
    required this.name,
    required this.availableSpots,
    required this.totalSpots,
    required this.imageUrl,
    this.locationDescription,
    this.latitude, // <--- ADD TO CONSTRUCTOR
    this.longitude, // <--- ADD TO CONSTRUCTOR
  });

  factory Cemetery.fromJson(Map<String, dynamic> json) {
    return Cemetery(
      id: json['id'] as String,
      name: json['name'] as String,
      availableSpots: json['available_spots'] as int? ?? 0,
      totalSpots: json['total_spots'] as int? ?? 0,
      imageUrl:
          json['image_url'] as String? ??
          'https://via.placeholder.com/400x200.png?text=No+Image',
      locationDescription: json['location_description'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(), // <--- PARSE LATITUDE
      longitude:
          (json['longitude'] as num?)?.toDouble(), // <--- PARSE LONGITUDE
    );
  }
}

// Update your sampleCemeteries with latitude and longitude
List<Cemetery> sampleCemeteries = [
  Cemetery(
    id: '1',
    name: 'Lang’ata Cemetery',
    availableSpots: 50,
    totalSpots: 100,
    imageUrl: 'https://picsum.photos/seed/langata/400/200',
    locationDescription: 'Lang\'ata Road, Nairobi',
    latitude: -1.32932, // Example Latitude for Lang'ata
    longitude: 36.78885, // Example Longitude for Lang'ata
  ),
  Cemetery(
    id: '2',
    name: 'Kariokor Cemetery',
    availableSpots: 20,
    totalSpots: 80,
    imageUrl: 'https://picsum.photos/seed/kariokor/400/200',
    locationDescription: 'Kariokor, Nairobi City',
    latitude: -1.2790, // Example Latitude for Kariokor
    longitude: 36.8321, // Example Longitude for Kariokor
  ),
  Cemetery(
    id: '3',
    name: 'City Park Cemetery',
    availableSpots: 75,
    totalSpots: 150,
    imageUrl: 'https://picsum.photos/seed/citypark/400/200',
    locationDescription: 'Limuru Road, Nairobi',
    latitude: -1.2645, // Example Latitude for City Park
    longitude: 36.8145, // Example Longitude for City Park
  ),
];
