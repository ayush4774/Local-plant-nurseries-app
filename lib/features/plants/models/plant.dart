class Plant {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String type; // indoor, outdoor
  final int wateringFrequency; // days between watering
  final String sunlight; // low, medium, high
  final String maintenance; // low, medium, high
  final DateTime? lastWatered;
  final DateTime? lastFertilized;
  final String? healthStatus; // healthy, needs-attention, critical
  final String? scientificName;
  final String? category;
  final String? waterFrequencyText;
  final String? soil;
  final String? origin;

  Plant({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.type = 'indoor',
    this.wateringFrequency = 7,
    this.sunlight = 'medium',
    this.maintenance = 'low',
    this.lastWatered,
    this.lastFertilized,
    this.healthStatus = 'healthy',
    this.scientificName,
    this.category,
    this.waterFrequencyText,
    this.soil,
    this.origin,
  });

  // Calculate days until next watering
  int get daysUntilWatering {
    if (lastWatered == null) return 0;
    final nextWatering = lastWatered!.add(Duration(days: wateringFrequency));
    final daysLeft = nextWatering.difference(DateTime.now()).inDays;
    return daysLeft < 0 ? 0 : daysLeft;
  }

  // Check if plant needs water
  bool get needsWater => daysUntilWatering == 0;

  // Convert from Firestore document
  factory Plant.fromMap(Map<String, dynamic> map, String id) {
    return Plant(
      id: id,
      name: map['name'] ?? map['commonName'] ?? '',
      description: map['description'],
      imageUrl: map['imageUrl'],
      type: map['type'] ?? _getCategoryType(map['category']),
      wateringFrequency: map['wateringFrequency'] ?? _parseWaterFrequency(map['waterFrequency']),
      sunlight: map['sunlight'] ?? 'medium',
      maintenance: map['maintenance'] ?? 'low',
      lastWatered: map['lastWatered'] != null 
          ? DateTime.parse(map['lastWatered']) 
          : null,
      lastFertilized: map['lastFertilized'] != null 
          ? DateTime.parse(map['lastFertilized']) 
          : null,
      healthStatus: map['healthStatus'] ?? 'healthy',
      scientificName: map['scientificName'],
      category: map['category'],
      waterFrequencyText: map['waterFrequency'],
      soil: map['soil'],
      origin: map['origin'],
    );
  }

  // Factory for loading from JSON asset file
  factory Plant.fromJson(Map<String, dynamic> json, int index) {
    return Plant(
      id: index.toString(),
      name: json['commonName'] ?? '',
      description: json['description'],
      scientificName: json['scientificName'],
      category: json['category'],
      type: _getCategoryType(json['category']),
      wateringFrequency: _parseWaterFrequency(json['waterFrequency']),
      waterFrequencyText: json['waterFrequency'],
      sunlight: json['sunlight'] ?? 'medium',
      maintenance: 'low',
      soil: json['soil'],
      origin: json['origin'],
      healthStatus: 'healthy',
    );
  }

  static String _getCategoryType(String? category) {
    if (category == null) return 'indoor';
    switch (category.toLowerCase()) {
      case 'indoor':
        return 'indoor';
      case 'outdoor':
      case 'tree':
      case 'flowering':
        return 'outdoor';
      case 'medicinal':
        return 'medicinal';
      default:
        return 'indoor';
    }
  }

  static int _parseWaterFrequency(String? freq) {
    if (freq == null) return 7;
    final lower = freq.toLowerCase();
    if (lower.contains('daily') || lower.contains('every day')) return 1;
    if (lower.contains('2 days') || lower.contains('2-3 days')) return 2;
    if (lower.contains('3 days') || lower.contains('3-4 days')) return 3;
    if (lower.contains('week')) return 7;
    if (lower.contains('2 weeks') || lower.contains('1-2 weeks')) return 14;
    if (lower.contains('3 weeks') || lower.contains('2-3 weeks')) return 21;
    return 7;
  }

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'type': type,
      'wateringFrequency': wateringFrequency,
      'sunlight': sunlight,
      'maintenance': maintenance,
      'lastWatered': lastWatered?.toIso8601String(),
      'lastFertilized': lastFertilized?.toIso8601String(),
      'healthStatus': healthStatus,
    };
  }
}

// Reminder model
class PlantReminder {
  final String id;
  final String plantId;
  final String plantName;
  final String type; // watering, fertilizing, repotting
  final String frequency; // daily, weekly, custom
  final int? customDays;
  final DateTime time;
  final bool isActive;

  PlantReminder({
    required this.id,
    required this.plantId,
    required this.plantName,
    required this.type,
    required this.frequency,
    this.customDays,
    required this.time,
    this.isActive = true,
  });

  factory PlantReminder.fromMap(Map<String, dynamic> map, String id) {
    return PlantReminder(
      id: id,
      plantId: map['plantId'] ?? '',
      plantName: map['plantName'] ?? '',
      type: map['type'] ?? 'watering',
      frequency: map['frequency'] ?? 'weekly',
      customDays: map['customDays'],
      time: DateTime.parse(map['time']),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plantId': plantId,
      'plantName': plantName,
      'type': type,
      'frequency': frequency,
      'customDays': customDays,
      'time': time.toIso8601String(),
      'isActive': isActive,
    };
  }
}
