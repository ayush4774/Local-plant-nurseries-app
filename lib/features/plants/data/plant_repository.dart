import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/plant.dart';

class PlantRepository {
  List<Plant>? _cachedPlants;

  Future<List<Plant>> fetchPlants() async {
    if (_cachedPlants != null) {
      debugPrint('PlantRepository: Returning ${_cachedPlants!.length} cached plants');
      return _cachedPlants!;
    }
    
    try {
      debugPrint('PlantRepository: Loading plants from JSON...');
      final jsonString = await rootBundle.loadString('assets/plants_data.json');
      debugPrint('PlantRepository: JSON loaded, length: ${jsonString.length}');
      final List<dynamic> jsonList = json.decode(jsonString);
      debugPrint('PlantRepository: Decoded ${jsonList.length} items');
      
      final List<Plant> plants = [];
      for (int i = 0; i < jsonList.length; i++) {
        try {
          final plant = Plant.fromJson(jsonList[i] as Map<String, dynamic>, i + 1);
          plants.add(plant);
        } catch (e) {
          debugPrint('PlantRepository: Error parsing plant $i: $e');
        }
      }
      
      _cachedPlants = plants;
      debugPrint('PlantRepository: Created ${_cachedPlants!.length} Plant objects');
      return _cachedPlants!;
    } catch (e, stack) {
      debugPrint('PlantRepository ERROR: $e');
      debugPrint('PlantRepository STACK: $stack');
      // Return fallback sample plants if JSON fails
      return _getFallbackPlants();
    }
  }

  List<Plant> _getFallbackPlants() {
    return [
      Plant(
        id: '1',
        name: 'Tulsi',
        description: 'A sacred medicinal plant widely grown in Indian households.',
        type: 'medicinal',
        sunlight: 'high',
        wateringFrequency: 2,
        healthStatus: 'healthy',
      ),
      Plant(
        id: '2',
        name: 'Money Plant',
        description: 'A popular trailing vine believed to bring prosperity.',
        type: 'indoor',
        sunlight: 'medium',
        wateringFrequency: 7,
        healthStatus: 'healthy',
      ),
      Plant(
        id: '3',
        name: 'Aloe Vera',
        description: 'A succulent plant known for its gel-filled leaves.',
        type: 'medicinal',
        sunlight: 'medium',
        wateringFrequency: 14,
        healthStatus: 'healthy',
      ),
    ];
  }

  Future<Plant?> getPlantById(String id) async {
    final list = await fetchPlants();
    for (final plant in list) {
      if (plant.id == id) {
        return plant;
      }
    }
    return null;
  }

  Future<void> addPlant(Plant plant) async {
    _cachedPlants?.add(plant);
  }

  Future<void> updatePlant(Plant plant) async {
    if (_cachedPlants == null) return;
    final index = _cachedPlants!.indexWhere((p) => p.id == plant.id);
    if (index != -1) {
      _cachedPlants![index] = plant;
    }
  }

  Future<void> deletePlant(String id) async {
    _cachedPlants?.removeWhere((p) => p.id == id);
  }

  // Search plants by name or category
  Future<List<Plant>> searchPlants(String query) async {
    final plants = await fetchPlants();
    final lowerQuery = query.toLowerCase();
    return plants.where((p) {
      return p.name.toLowerCase().contains(lowerQuery) ||
          (p.scientificName?.toLowerCase().contains(lowerQuery) ?? false) ||
          (p.category?.toLowerCase().contains(lowerQuery) ?? false) ||
          (p.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  // Filter by category
  Future<List<Plant>> getPlantsByCategory(String category) async {
    final plants = await fetchPlants();
    return plants.where((p) => p.category?.toLowerCase() == category.toLowerCase()).toList();
  }

  // Filter by type
  Future<List<Plant>> getPlantsByType(String type) async {
    final plants = await fetchPlants();
    return plants.where((p) => p.type.toLowerCase() == type.toLowerCase()).toList();
  }
}
