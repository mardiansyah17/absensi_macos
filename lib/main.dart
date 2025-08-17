import 'package:face_client/widgets/layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Athena HR — Template',
      themeMode: ThemeMode.light, // Light only
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2563EB), // Calm blue seed
        brightness: Brightness.light,
        visualDensity: VisualDensity.compact,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const Layout(),
    );
  }
}
