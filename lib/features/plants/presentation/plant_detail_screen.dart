import 'package:flutter/material.dart';
import '../../plants/models/plant.dart';
import '../../../core/services/notification_service.dart';

class PlantDetailScreen extends StatefulWidget {
  final Plant? plant;

  const PlantDetailScreen({super.key, this.plant});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> _activeReminders = [];

  @override
  void initState() {
    super.initState();
    if (widget.plant != null) {
      _loadPlantReminders();
    }
  }

  Future<void> _loadPlantReminders() async {
    final reminders =
        await _notificationService.getRemindersForPlant(widget.plant!.id);
    setState(() => _activeReminders = reminders);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.plant == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Plant')),
        body: const Center(child: Text('Plant not found')),
      );
    }

    final plant = widget.plant!;

    return Scaffold(
      appBar: AppBar(
        title: Text(plant.name),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Set Reminder',
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/reminder',
                arguments: plant,
              ).then((_) => _loadPlantReminders());
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plant Image
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withAlpha(40),
              ),
              child: plant.imageUrl != null && plant.imageUrl!.isNotEmpty
                  ? Image.network(
                      plant.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlantIcon(),
                    )
                  : _buildPlantIcon(),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Scientific Name
                  Text(
                    plant.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (plant.scientificName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      plant.scientificName!,
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Info Cards Row
                  Row(
                    children: [
                      Expanded(
                          child: _buildInfoCard('Type',
                              plant.type.toUpperCase(), Icons.home, isDark)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildInfoCard(
                              'Sunlight',
                              plant.sunlight.toUpperCase(),
                              Icons.wb_sunny,
                              isDark)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildInfoCard(
                              'Care',
                              plant.maintenance.toUpperCase(),
                              Icons.spa,
                              isDark)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Active Reminders
                  if (_activeReminders.isNotEmpty) ...[
                    const Text(
                      'Active Reminders',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._activeReminders
                        .map((r) => _buildReminderChip(r, isDark)),
                    const SizedBox(height: 24),
                  ],

                  // Set Reminder Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/reminder',
                          arguments: plant,
                        ).then((_) => _loadPlantReminders());
                      },
                      icon: const Icon(Icons.add_alarm),
                      label: const Text('Set Reminder'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E7D32),
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description
                  if (plant.description != null &&
                      plant.description!.isNotEmpty) ...[
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plant.description!,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Care Details
                  const Text(
                    'Care Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildDetailRow(
                      Icons.water_drop,
                      'Watering',
                      plant.waterFrequencyText ??
                          'Every ${plant.wateringFrequency} days',
                      isDark),

                  if (plant.soil != null)
                    _buildDetailRow(Icons.grass, 'Soil', plant.soil!, isDark),

                  if (plant.origin != null)
                    _buildDetailRow(
                        Icons.public, 'Origin', plant.origin!, isDark),

                  if (plant.category != null)
                    _buildDetailRow(
                        Icons.category, 'Category', plant.category!, isDark),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderChip(Map<String, dynamic> reminder, bool isDark) {
    final type = reminder['reminderType'] ?? 'watering';
    final hour = reminder['hour'] ?? 9;
    final minute = reminder['minute'] ?? 0;
    final frequencyDays = reminder['frequencyDays'] ?? 7;
    final timeStr = TimeOfDay(hour: hour, minute: minute).format(context);

    IconData icon;
    Color color;
    String label;

    switch (type) {
      case 'watering':
        icon = Icons.water_drop_outlined;
        color = Colors.blue;
        label = 'Watering';
        break;
      case 'fertilizing':
        icon = Icons.eco_outlined;
        color = Colors.green;
        label = 'Fertilizing';
        break;
      case 'repotting':
        icon = Icons.yard_outlined;
        color = Colors.brown;
        label = 'Repotting';
        break;
      default:
        icon = Icons.notifications_outlined;
        color = const Color(0xFF2E7D32);
        label = 'Care';
    }

    String freq = frequencyDays == 1
        ? 'Daily'
        : frequencyDays == 7
            ? 'Weekly'
            : 'Every $frequencyDays days';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            '$label • $freq • $timeStr',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantIcon() {
    return Center(
      child: Icon(
        Icons.local_florist,
        size: 80,
        color: const Color(0xFF2E7D32).withAlpha(150),
      ),
    );
  }

  Widget _buildInfoCard(
      String label, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF2E7D32), size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2E7D32), size: 22),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
