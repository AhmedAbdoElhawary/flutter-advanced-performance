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
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF101113),
      ),
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
  int _count = 20000;
  double _sliderValue = 20000;

  @override
  Widget build(BuildContext context) {
    final color = _kind.color;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 160, child: PerformanceOverlay.allEnabled()),
              const SizedBox(height: 16),
              Expanded(
                child: SimulationView(
                  key: ValueKey((_kind, _count)),
                  kind: _kind,
                  count: _count,
                ),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      '${_withCommas(_sliderValue.round())} particles',
                      style: const TextStyle(fontSize: 14, color: Color(0xFFB8BCC2)),
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: _sliderValue,
                      min: 5000,
                      max: 50000,
                      divisions: 9,
                      activeColor: color,
                      onChanged: (value) => setState(() => _sliderValue = value),
                      onChangeEnd: (value) => setState(() => _count = value.round()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _withCommas(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
        );
  }
}

class _StorageButton extends StatelessWidget {
  const _StorageButton({
    required this.kind,
    required this.selected,
    required this.onPressed,
  });

  final StorageKind kind;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = selected ? kind.color : const Color(0xFFB8BCC2);

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        foregroundColor: color,
        side: BorderSide(color: selected ? kind.color : const Color(0xFF2A2D33)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: TextStyle(
          fontSize: 15,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      child: Text(kind.label),
    );
  }
}