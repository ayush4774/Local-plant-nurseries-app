import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'router.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Plant Nurseries',
      theme: appTheme,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: '/',
    );
  }
}
