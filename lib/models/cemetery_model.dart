// lib/models/cemetery_model.dart
class Cemetery {
  final String id;
  final String name;
  final int availableSpots;
  final int totalSpots;
  final String imageUrl;
  final String? locationDescription;
  final double? latitude;
  final double? longitude;
  // Add any other fields that match your Supabase table

  Cemetery({
    required this.id,
    required this.name,
    required this.availableSpots,
    required this.totalSpots,
    required this.imageUrl,
    this.locationDescription,
    this.latitude,
    this.longitude,
  });

  factory Cemetery.fromJson(Map<String, dynamic> json) {
    return Cemetery(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unknown Cemetery',
      availableSpots: json['available_spots'] as int? ?? 0,
      totalSpots: json['total_spots'] as int? ?? 0,
      // For imageUrl, if storing path from Supabase Storage:
      // imageUrl: json['image_url'] != null ? supabase.storage.from('your_bucket_name').getPublicUrl(json['image_url']).data : 'https://via.placeholder.com/400x200.png?text=No+Image',
      // For now, assuming it's a direct URL or you handle storage URL generation elsewhere
      imageUrl:
          json['image_url'] as String? ??
          'https://via.placeholder.com/400x200.png?text=No+Image',
      locationDescription: json['location_description'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
  // No toJson needed if users don't create cemeteries via the app
}

// Remove 'sampleCemeteries' list from here if you're fetching from Supabase
// List<Cemetery> sampleCemeteries = [ ... ];
