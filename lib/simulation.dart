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
  CustomSimulation(this.count) : points = Float32List(count * 2), lines = Float32List(maxLines * 4);

  factory CustomSimulation.create(StorageKind kind, int count) {
    return switch (kind) {
      StorageKind.boxed => BoxedSimulation(count),
      StorageKind.typed => TypedSimulation(count),
    };
  }

  static const double dt = 1 / 60;
  static const double spring = 4;
  static const int linkedCount = 300;
  static const double linkReach = 60;
  static const int maxLines = 5000;

  final int count;
  final Float32List points;
  final Float32List lines;
  int lineCount = 0;

  int get newObjectsPerFrame;

  void step(Size size) {
    moveParticles(size.width, size.height);
    _linkNearby();
    notifyListeners();
  }

  @protected
  void moveParticles(double width, double height);

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

  void _linkNearby() {
    final linked = min(count, linkedCount);
    const reachSquared = linkReach * linkReach;
    var segments = 0;

    for (var i = 0; i < linked && segments < maxLines; i++) {
      final x1 = points[i * 2];
      final y1 = points[i * 2 + 1];

      for (var j = i + 1; j < linked && segments < maxLines; j++) {
        final x2 = points[j * 2];
        final y2 = points[j * 2 + 1];
        final dx = x2 - x1;
        final dy = y2 - y1;
        if (dx * dx + dy * dy > reachSquared) continue;

        final k = segments * 4;
        lines[k] = x1;
        lines[k + 1] = y1;
        lines[k + 2] = x2;
        lines[k + 3] = y2;
        segments++;
      }
    }

    lineCount = segments;
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
  int get newObjectsPerFrame => count * 6;

  // Same math as TypedSimulation on purpose: only the list type differs.
  @override
  void moveParticles(double width, double height) {
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
  void moveParticles(double width, double height) {
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

      points[i * 2] = _x[i] * width;
      points[i * 2 + 1] = _y[i] * height;
    }
  }
}
