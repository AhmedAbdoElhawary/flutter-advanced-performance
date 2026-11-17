import 'dart:math' show pi;
import 'dart:ui' show PointMode;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_advanced_performance/list_vs_float64/simulation.dart';
import 'package:flutter_advanced_performance/scale.dart';

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
  int _stepMicros = 0;

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
    _stepMicros += _stopwatch.elapsedMicroseconds;

    final window = elapsed - _windowStart;
    if (window < const Duration(seconds: 1)) return;

    _stats.value = FrameStats(
      fps: (_frames * Duration.microsecondsPerSecond / window.inMicroseconds).round(),
      stepMs: _stepMicros / _frames / 1000,
    );
    _frames = 0;
    _stepMicros = 0;
    _windowStart = elapsed;
  }

  @override
  Widget build(BuildContext context) {
    final scale = context.scale;
    final color = widget.kind.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ValueListenableBuilder(
          valueListenable: _stats,
          builder: (context, stats, _) => _StatsRow(stats: stats, count: widget.count, color: color),
        ),
        SizedBox(height: 16 * scale),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6 * scale),
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
  const FrameStats({required this.fps, required this.stepMs});

  static const empty = FrameStats(fps: 0, stepMs: 0);

  final int fps;

  /// Average time of one simulation step per frame (64 moves + writing the points), measured with a Stopwatch.
  final double stepMs;
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats, required this.count, required this.color});

  final FrameStats stats;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scale = context.scale;
    final muted = TextStyle(fontSize: 34 * scale, color: const Color(0xFFB8BCC2));
    final dots = '$count'.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    var info = '';
    if (stats.fps > 0) {
      final timeScale = stats.fps * CustomSimulation.dt * CustomSimulation.stepsPerFrame;
      final fastestLap = (2 * pi / CustomSimulation.maxSpeed / timeScale).round();
      final slowestLap = (2 * pi / CustomSimulation.minSpeed / timeScale).round();
      info = '1 lap every $fastestLap–$slowestLap s';
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
              style: TextStyle(fontSize: 48 * scale, fontWeight: FontWeight.w600, color: color),
            ),
            Text('sim ${stats.stepMs.toStringAsFixed(1)} ms / frame', style: muted, overflow: TextOverflow.ellipsis),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('$dots dots', style: muted, overflow: TextOverflow.ellipsis),
            Text(info, style: muted, overflow: TextOverflow.ellipsis),
          ],
        ),
      ],
    );
  }
}

class ParticlePainter extends CustomPainter {
  ParticlePainter(this.simulation, Color color)
    : _dotPaint = Paint()
        ..color = color
        ..strokeWidth = 1,
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