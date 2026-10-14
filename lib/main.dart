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

/*
import 'dart:math';
import 'dart:ui' show Color, Size;

import 'package:flutter/foundation.dart';

enum StorageKind {
  boxed('List<double>', Color(0xFFE5484D)),
  typed('Float64List', Color(0xFF46D17F));

  const StorageKind(this.label, this.color);

  final String label;
  final Color color;
}

abstract class CustomSimulation extends ChangeNotifier {
  CustomSimulation(this.count) : points = Float32List(count * 2);

  factory CustomSimulation.create(StorageKind kind, int count) {
    return switch (kind) {
      StorageKind.boxed => BoxedSimulation(count),
      StorageKind.typed => TypedSimulation(count),
    };
  }

  static const int substeps = 8;
  static const double dt = 1 / 60 / substeps;
  static const double spring = 4;

  final int count;
  final Float32List points;

  int get newObjectsPerFrame;

  void step(Size size) {
    for (var i = 0; i < substeps; i++) {
      moveParticles();
    }
    writePoints(size.width, size.height);
    notifyListeners();
  }

  @protected
  void moveParticles();

  @protected
  void writePoints(double width, double height);

  @protected
  void seed(void Function(int i, double x, double y, double vx, double vy) write) {
    final random = Random(42);
    for (var i = 0; i < count; i++) {
      final x = random.nextDouble();
      final y = random.nextDouble();
      final speed = 1 + random.nextDouble() * 2;
      write(i, x, y, -(y - 0.5) * speed, (x - 0.5) * speed);
    }
  }
}

class BoxedSimulation extends CustomSimulation {
  BoxedSimulation(super.count)
    : _x = _zeros(count),
      _y = _zeros(count),
      _vx = _zeros(count),
      _vy = _zeros(count),
      _ax = _zeros(count),
      _ay = _zeros(count) {
    seed((i, x, y, vx, vy) {
      _x[i] = x;
      _y[i] = y;
      _vx[i] = vx;
      _vy[i] = vy;
    });
  }

  static List<double> _zeros(int count) => List.generate(count, (_) => 0.0);

  final List<double> _x;
  final List<double> _y;
  final List<double> _vx;
  final List<double> _vy;
  final List<double> _ax;
  final List<double> _ay;

  @override
  int get newObjectsPerFrame => count * 6 * CustomSimulation.substeps;

  // duplicated on purpose, shared code over List<double> makes Float64List box too
  @override
  void moveParticles() {
    for (var i = 0; i < count; i++) {
      _ax[i] = -(_x[i] - 0.5) * CustomSimulation.spring;
      _ay[i] = -(_y[i] - 0.5) * CustomSimulation.spring;

      _vx[i] += _ax[i] * CustomSimulation.dt;
      _vy[i] += _ay[i] * CustomSimulation.dt;

      _x[i] += _vx[i] * CustomSimulation.dt;
      _y[i] += _vy[i] * CustomSimulation.dt;

      if (_x[i] < 0.0 || _x[i] > 1.0) {
        _x[i] = _x[i] < 0.0 ? 0.0 : 1.0;
        _vx[i] = -_vx[i];
      }
      if (_y[i] < 0.0 || _y[i] > 1.0) {
        _y[i] = _y[i] < 0.0 ? 0.0 : 1.0;
        _vy[i] = -_vy[i];
      }
    }
  }

  @override
  void writePoints(double width, double height) {
    for (var i = 0; i < count; i++) {
      points[i * 2] = _x[i] * width;
      points[i * 2 + 1] = _y[i] * height;
    }
  }
}

class TypedSimulation extends CustomSimulation {
  TypedSimulation(super.count)
    : _x = Float64List(count),
      _y = Float64List(count),
      _vx = Float64List(count),
      _vy = Float64List(count),
      _ax = Float64List(count),
      _ay = Float64List(count) {
    seed((i, x, y, vx, vy) {
      _x[i] = x;
      _y[i] = y;
      _vx[i] = vx;
      _vy[i] = vy;
    });
  }

  final Float64List _x;
  final Float64List _y;
  final Float64List _vx;
  final Float64List _vy;
  final Float64List _ax;
  final Float64List _ay;

  @override
  int get newObjectsPerFrame => 0;

  @override
  void moveParticles() {
    for (var i = 0; i < count; i++) {
      _ax[i] = -(_x[i] - 0.5) * CustomSimulation.spring;
      _ay[i] = -(_y[i] - 0.5) * CustomSimulation.spring;

      _vx[i] += _ax[i] * CustomSimulation.dt;
      _vy[i] += _ay[i] * CustomSimulation.dt;

      _x[i] += _vx[i] * CustomSimulation.dt;
      _y[i] += _vy[i] * CustomSimulation.dt;

      if (_x[i] < 0.0 || _x[i] > 1.0) {
        _x[i] = _x[i] < 0.0 ? 0.0 : 1.0;
        _vx[i] = -_vx[i];
      }
      if (_y[i] < 0.0 || _y[i] > 1.0) {
        _y[i] = _y[i] < 0.0 ? 0.0 : 1.0;
        _vy[i] = -_vy[i];
      }
    }
  }

  @override
  void writePoints(double width, double height) {
    for (var i = 0; i < count; i++) {
      points[i * 2] = _x[i] * width;
      points[i * 2 + 1] = _y[i] * height;
    }
  }
}

*/
