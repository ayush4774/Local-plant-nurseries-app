import '../models/plant.dart';

class PlantRepository {
  Future<List<Plant>> fetchPlants() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      Plant(id: '1', name: 'Fiddle Leaf Fig', description: 'Easy indoor plant'),
    ];
  }

  Future<Plant?> getPlantById(String id) async {
    final list = await fetchPlants();
    return list.firstWhere((p) => p.id == id, orElse: () => null);
  }
}
