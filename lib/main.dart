import 'package:flutter/material.dart';

import 'home_page.dart';

void main() {
  runApp(const ParticleBenchApp());
}

class ParticleBenchApp extends StatelessWidget {
  const ParticleBenchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: const Color(0xFF101113)),
      home: const HomePage(),
    );
  }
}
