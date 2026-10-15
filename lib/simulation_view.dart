import 'dart:math' show pi;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_advanced_performance/simulation.dart';

class SimulationView extends StatefulWidget {
  const SimulationView({super.key, required this.kind, required this.count});

  final StorageKind kind;
  final int count;

  @override
  State<SimulationView> createState() => _SimulationViewState();
}

class _SimulationViewState extends State<SimulationView> with SingleTickerProviderStateMixin {
  late final CustomSimulation _simulation = CustomSimulation.create(widget.kind, widget.count);
  late final Ticker _ticker = createTicker(_onTick);
  final _stats = ValueNotifier(FrameStats.empty);
  final _stopwatch = Stopwatch();

  Size _fieldSize = Size.zero;
  Duration _windowStart = Duration.zero;
  int _frames = 0;

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _simulation.dispose();
    _stats.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_fieldSize.isEmpty) return;

    _stopwatch
      ..reset()
      ..start();
    _simulation.step(_fieldSize);
    _stopwatch.stop();

    _frames++;

    final window = elapsed - _windowStart;
    if (window < const Duration(seconds: 1)) return;

    _stats.value = FrameStats(
      fps: (_frames * Duration.microsecondsPerSecond / window.inMicroseconds).round(),
    );
    _frames = 0;
    _windowStart = elapsed;
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.kind.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ValueListenableBuilder(
          valueListenable: _stats,
          builder: (context, stats, _) => _StatsRow(
            stats: stats,
            count: widget.count,
            newObjects: _simulation.newObjectsPerFrame,
            color: color,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: ColoredBox(
              color: const Color(0xFF0B0C0E),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _fieldSize = constraints.biggest;
                  return CustomPaint(size: Size.infinite, painter: ParticlePainter(_simulation, color));
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class FrameStats {
  const FrameStats({required this.fps});

  static const empty = FrameStats(fps: 0);

  final int fps;
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats, required this.count, required this.newObjects, required this.color});

  final FrameStats stats;
  final int count;
  final int newObjects;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const muted = TextStyle(fontSize: 34, color: Color(0xFFB8BCC2));
    final perSecond = newObjects * stats.fps;
    final objects = switch (perSecond) {
      >= 1000000 => '${(perSecond / 1000000).round()}M',
      >= 1000 => '${(perSecond / 1000).round()}k',
      _ => '$perSecond',
    };
    final dots = '$count'.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    var info = '$dots dots';
    if (stats.fps > 0) {
      final timeScale = stats.fps * CustomSimulation.dt * CustomSimulation.stepsPerFrame;
      final fastestLap = (2 * pi / CustomSimulation.maxSpeed / timeScale).round();
      final slowestLap = (2 * pi / CustomSimulation.minSpeed / timeScale).round();
      info += ' · 1 lap every $fastestLap–$slowestLap s';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${stats.fps} FPS',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.w600, color: color),
            ),
            Text('$objects objects/s', style: muted, overflow: TextOverflow.ellipsis),
          ],
        ),
        Text(info, style: muted, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class ParticlePainter extends CustomPainter {
  ParticlePainter(this.simulation, Color color)
    : _dotPaint = Paint()
        ..color = color
        ..strokeWidth = 2,
      super(repaint: simulation);

  final CustomSimulation simulation;
  final Paint _dotPaint;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRawPoints(PointMode.points, simulation.points, _dotPaint);
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.simulation != simulation || oldDelegate._dotPaint.color != _dotPaint.color;
  }
}
