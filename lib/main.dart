import 'package:flutter/material.dart';

import 'simulation.dart';
import 'simulation_view.dart';

void main() => runApp(const ParticleBenchApp());

class ParticleBenchApp extends StatelessWidget {
  const ParticleBenchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: const Color(0xFF101113)),
      home: const BenchPage(),
    );
  }
}

class BenchPage extends StatefulWidget {
  const BenchPage({super.key});

  @override
  State<BenchPage> createState() => _BenchPageState();
}

class _BenchPageState extends State<BenchPage> {
  StorageKind _kind = StorageKind.boxed;
  final int _count = 100000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 150),
              Expanded(
                child: SimulationView(key: ValueKey((_kind, _count)), kind: _kind, count: _count),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final kind in StorageKind.values) ...[
                    if (kind != StorageKind.values.first) const SizedBox(width: 8),
                    Expanded(
                      child: _StorageButton(
                        kind: kind,
                        selected: kind == _kind,
                        onPressed: () => setState(() => _kind = kind),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorageButton extends StatelessWidget {
  const _StorageButton({required this.kind, required this.selected, required this.onPressed});

  final StorageKind kind;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = selected ? kind.color : const Color(0xFFB8BCC2);

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(65),
        foregroundColor: color,
        side: BorderSide(color: selected ? kind.color : const Color(0xFF2A2D33)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: TextStyle(fontSize: 30, fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
      ),
      child: Text(kind.label),
    );
  }
}
