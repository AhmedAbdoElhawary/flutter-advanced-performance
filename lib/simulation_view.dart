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
          builder: (context, stats, _) =>
              _StatsRow(stats: stats, newObjects: _simulation.newObjectsPerFrame, color: color),
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
  const _StatsRow({required this.stats, required this.newObjects, required this.color});

  final FrameStats stats;
  final int newObjects;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const muted = TextStyle(fontSize: 34, color: Color(0xFFB8BCC2));
    final objects = switch (newObjects) {
      >= 1000000 => '${(newObjects / 1000000).toStringAsFixed(1)}M',
      >= 1000 => '${(newObjects / 1000).round()}k',
      _ => '$newObjects',
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '${stats.fps} FPS',
          style: TextStyle(fontSize: 48, fontWeight: FontWeight.w600, color: color),
        ),
        Text('$objects objects/frame', style: muted, overflow: TextOverflow.ellipsis),
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
