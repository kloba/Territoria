import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'simple_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const TerritoriaApp());
}

class TerritoriaApp extends StatelessWidget {
  const TerritoriaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Territoria',
      theme: ThemeData(
        primaryColor: const Color(0xFF1976D2),
        scaffoldBackgroundColor: const Color(0xFF0D47A1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.dark,
        ),
      ),
      home: const SimpleGame(),
      debugShowCheckedModeBanner: false,
    );
  }
}