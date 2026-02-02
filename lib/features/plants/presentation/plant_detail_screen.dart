import 'package:flutter/material.dart';
import '../../plants/models/plant.dart';

class PlantDetailScreen extends StatelessWidget {
  final Plant? plant;

  const PlantDetailScreen({Key? key, this.plant}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(plant?.name ?? 'Plant')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(plant?.description ?? 'No details'),
      ),
    );
  }
}
