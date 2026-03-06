import 'package:flutter/material.dart';
import '../features/plants/presentation/dashboard_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/plants/presentation/plant_detail_screen.dart';
import '../features/plants/presentation/add_plant_screen.dart';
import '../features/plants/presentation/search_screen.dart';
import '../features/plants/presentation/set_reminder_screen.dart';
import '../features/plants/presentation/reminders_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/plants/models/plant.dart';

class AppRouter {
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/signup':
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case '/add':
        return MaterialPageRoute(builder: (_) => const AddPlantScreen());
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case '/search':
        return MaterialPageRoute(builder: (_) => const SearchScreen());
      case '/reminders':
        return MaterialPageRoute(builder: (_) => const RemindersScreen());
      case '/reminder':
        final plant = settings.arguments as Plant?;
        return MaterialPageRoute(
          builder: (_) => SetReminderScreen(preselectedPlant: plant),
        );
      case '/details':
        final plant = settings.arguments as Plant?;
        return MaterialPageRoute(
            builder: (_) => PlantDetailScreen(plant: plant));
      default:
        return MaterialPageRoute(
            builder: (_) =>
                const Scaffold(body: Center(child: Text('Unknown route'))));
    }
  }
}
