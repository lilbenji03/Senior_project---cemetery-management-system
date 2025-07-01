// lib/models/cemetery_model.dart

class Cemetery {
  final String id;
  final String name;
  final int availableSpaces; // Changed from availableSpots
  final int totalSpaces; // Changed from totalSpots
  final String imageUrl;
  final String? locationDescription;
  final double? latitude;
  final double? longitude;
  // Add any other fields that match your Supabase table

  Cemetery({
    required this.id,
    required this.name,
    required this.availableSpaces, // Changed from availableSpots
    required this.totalSpaces, // Changed from totalSpots
    required this.imageUrl,
    this.locationDescription,
    this.latitude,
    this.longitude,
  });

  factory Cemetery.fromJson(Map<String, dynamic> json) {
    return Cemetery(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unknown Cemetery',
      availableSpaces:
          json['available_spaces'] as int? ?? 0, // Changed from available_spots
      totalSpaces:
          json['total_spaces'] as int? ?? 0, // Changed from total_spots
      // For imageUrl, if storing path from Supabase Storage:
      // imageUrl: json['image_url'] != null ? supabase.storage.from('your_bucket_name').getPublicUrl(json['image_url']).data : 'https://via.placeholder.com/400x200.png?text=No+Image',
      // For now, assuming it's a direct URL or you handle storage URL generation elsewhere
      imageUrl: json['image_url'] as String? ??
          'https://via.placeholder.com/400x200.png?text=No+Image',
      locationDescription: json['location_description'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
  // No toJson needed if users don't create cemeteries via the app
}

// Remove 'sampleCemeteries' list from here if you're fetching from Supabase
