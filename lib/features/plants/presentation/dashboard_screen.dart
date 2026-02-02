import 'package:flutter/material.dart';
import '../../plants/data/plant_repository.dart';
import '../../plants/models/plant.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PlantRepository _repo = PlantRepository();
  late Future<List<Plant>> _plants;

  @override
  void initState() {
    super.initState();
    _plants = _repo.fetchPlants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plants Dashboard')),
      body: FutureBuilder<List<Plant>>(
        future: _plants,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final plants = snapshot.data ?? [];
          return ListView.builder(
            itemCount: plants.length,
            itemBuilder: (context, i) => ListTile(
              title: Text(plants[i].name),
              subtitle: Text(plants[i].description ?? ''),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
