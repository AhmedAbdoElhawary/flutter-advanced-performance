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

/// For [moveParticles] and [writePoints] cannot be in the contract, why?
/// becuase [_x], [_y], and [_speed],
/// you cannot unified them and find the common between List<double> and Float64,
///
abstract class CustomSimulation extends ChangeNotifier {
  CustomSimulation(this.count) : points = Float32List(count * 2);

  factory CustomSimulation.create(StorageKind kind, int count) {
    return switch (kind) {
      StorageKind.boxed => BoxedSimulation(count),
      StorageKind.typed => TypedSimulation(count),
    };
  }

  static const int stepsPerFrame = 64;
  static const double dt = 1 / 60 / stepsPerFrame;
  static const double minSpeed = 0.5;
  static const double maxSpeed = 1.5;

  final int count;
  final Float32List points;

  int get newObjectsPerFrame;

  void step(Size size) {
    for (var i = 0; i < stepsPerFrame; i++) {
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
  void seed(void Function(int i, double x, double y, double speed) write) {
    final random = Random(42);
    for (var i = 0; i < count; i++) {
      final radius = random.nextDouble();
      final angle = random.nextDouble() * 2 * pi;
      final speed = minSpeed + random.nextDouble() * (maxSpeed - minSpeed);
      write(i, radius * cos(angle), radius * sin(angle), speed);
    }
  }
}

class BoxedSimulation extends CustomSimulation {
  BoxedSimulation(super.count) : _x = _zeros(count), _y = _zeros(count), _speed = _zeros(count) {
    seed((i, x, y, speed) {
      _x[i] = x;
      _y[i] = y;
      _speed[i] = speed;
    });
  }

  static List<double> _zeros(int count) => List.generate(count, (_) => 0.0);

  final List<double> _x;
  final List<double> _y;
  final List<double> _speed;

  @override
  int get newObjectsPerFrame => count * 2 * CustomSimulation.stepsPerFrame;

  @override
  void moveParticles() {
    for (var i = 0; i < count; i++) {
      _x[i] -= _y[i] * _speed[i] * CustomSimulation.dt;
      _y[i] += _x[i] * _speed[i] * CustomSimulation.dt;
    }
  }

  @override
  void writePoints(double width, double height) {
    final radius = min(width, height) / 2;
    for (var i = 0; i < count; i++) {
      points[i * 2] = width / 2 + _x[i] * radius;
      points[i * 2 + 1] = height / 2 + _y[i] * radius;
    }
  }
}

class TypedSimulation extends CustomSimulation {
  TypedSimulation(super.count)
    : _x = Float64List(count),
      _y = Float64List(count),
      _speed = Float64List(count) {
    seed((i, x, y, speed) {
      _x[i] = x;
      _y[i] = y;
      _speed[i] = speed;
    });
  }

  final Float64List _x;
  final Float64List _y;
  final Float64List _speed;

  @override
  int get newObjectsPerFrame => 0;

  @override
  void moveParticles() {
    for (var i = 0; i < count; i++) {
      _x[i] -= _y[i] * _speed[i] * CustomSimulation.dt;
      _y[i] += _x[i] * _speed[i] * CustomSimulation.dt;
    }
  }

  @override
  void writePoints(double width, double height) {
    final radius = min(width, height) / 2;
    for (var i = 0; i < count; i++) {
      points[i * 2] = width / 2 + _x[i] * radius;
      points[i * 2 + 1] = height / 2 + _y[i] * radius;
    }
  }
}
