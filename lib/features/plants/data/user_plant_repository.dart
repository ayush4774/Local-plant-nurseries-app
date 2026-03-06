import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant.dart';

/// Repository for managing user's personal plant collection.
/// Plants are stored locally using SharedPreferences, scoped per user.
class UserPlantRepository {
  static const String _userPlantsKeyPrefix = 'user_plants_';

  List<Plant>? _cachedUserPlants;

  /// Get the storage key for the current user
  String get _userPlantsKey {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      return '$_userPlantsKeyPrefix$uid';
    }
    return '${_userPlantsKeyPrefix}anonymous';
  }

  /// Clear all cached data (call on sign-out)
  Future<void> clearUserData() async {
    _cachedUserPlants = null;
    debugPrint('UserPlantRepository: Cleared user data cache');
  }

  /// Get all plants in user's collection
  Future<List<Plant>> fetchUserPlants() async {
    if (_cachedUserPlants != null) {
      return _cachedUserPlants!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_userPlantsKey);

      if (jsonString == null || jsonString.isEmpty) {
        _cachedUserPlants = [];
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      _cachedUserPlants = jsonList.map((item) {
        return Plant.fromMap(item as Map<String, dynamic>, item['id'] ?? '');
      }).toList();

      debugPrint(
          'UserPlantRepository: Loaded ${_cachedUserPlants!.length} user plants');
      return _cachedUserPlants!;
    } catch (e) {
      debugPrint('UserPlantRepository ERROR: $e');
      _cachedUserPlants = [];
      return [];
    }
  }

  /// Add a plant from catalog to user's collection
  Future<bool> addPlantToCollection(Plant plant) async {
    try {
      final plants = await fetchUserPlants();

      // Check if plant already exists in collection
      if (plants.any((p) => p.id == plant.id)) {
        debugPrint(
            'UserPlantRepository: Plant ${plant.name} already in collection');
        return false;
      }

      // Add plant with current timestamp for lastWatered
      final newPlant = Plant(
        id: plant.id,
        name: plant.name,
        description: plant.description,
        imageUrl: plant.imageUrl,
        type: plant.type,
        wateringFrequency: plant.wateringFrequency,
        sunlight: plant.sunlight,
        maintenance: plant.maintenance,
        lastWatered: DateTime.now(),
        healthStatus: 'healthy',
        scientificName: plant.scientificName,
        category: plant.category,
        waterFrequencyText: plant.waterFrequencyText,
        soil: plant.soil,
        origin: plant.origin,
      );

      plants.add(newPlant);
      await _savePlants(plants);
      _cachedUserPlants = plants;

      debugPrint('UserPlantRepository: Added ${plant.name} to collection');
      return true;
    } catch (e) {
      debugPrint('UserPlantRepository ERROR adding plant: $e');
      return false;
    }
  }

  /// Remove a plant from user's collection
  Future<bool> removePlantFromCollection(String plantId) async {
    try {
      final plants = await fetchUserPlants();
      plants.removeWhere((p) => p.id == plantId);
      await _savePlants(plants);
      _cachedUserPlants = plants;

      debugPrint('UserPlantRepository: Removed plant $plantId from collection');
      return true;
    } catch (e) {
      debugPrint('UserPlantRepository ERROR removing plant: $e');
      return false;
    }
  }

  /// Update a plant in user's collection (e.g., update lastWatered)
  Future<bool> updatePlant(Plant plant) async {
    try {
      final plants = await fetchUserPlants();
      final index = plants.indexWhere((p) => p.id == plant.id);

      if (index == -1) {
        debugPrint('UserPlantRepository: Plant ${plant.id} not found');
        return false;
      }

      plants[index] = plant;
      await _savePlants(plants);
      _cachedUserPlants = plants;

      return true;
    } catch (e) {
      debugPrint('UserPlantRepository ERROR updating plant: $e');
      return false;
    }
  }

  /// Check if a plant is in user's collection
  Future<bool> isPlantInCollection(String plantId) async {
    final plants = await fetchUserPlants();
    return plants.any((p) => p.id == plantId);
  }

  /// Get a plant by ID from user's collection
  Future<Plant?> getPlantById(String id) async {
    final plants = await fetchUserPlants();
    for (final plant in plants) {
      if (plant.id == id) {
        return plant;
      }
    }
    return null;
  }

  /// Clear cache to force reload
  void clearCache() {
    _cachedUserPlants = null;
  }

  /// Save plants to SharedPreferences
  Future<void> _savePlants(List<Plant> plants) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = plants.map((p) => p.toMap()..['id'] = p.id).toList();
    await prefs.setString(_userPlantsKey, json.encode(jsonList));
  }
}
