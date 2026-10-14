import 'dart:typed_data' show Float32List;
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
  const FrameStats({required this.fps, required this.stepMs});

  static const empty = FrameStats(fps: 0, stepMs: 0);

  final int fps;
  final double stepMs;
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats, required this.newObjects, required this.color});

  final FrameStats stats;
  final int newObjects;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const muted = TextStyle(fontSize: 14, color: Color(0xFFB8BCC2));
    final objects = newObjects >= 1000 ? '${(newObjects / 1000).round()}k' : '$newObjects';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '${stats.fps} FPS',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: color),
        ),
        const SizedBox(width: 18),
        Flexible(
          child: Text('$objects objects/frame', style: muted, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 18),
        Text('step ${stats.stepMs.toStringAsFixed(1)} ms', style: muted),
      ],
    );
  }
}

class ParticlePainter extends CustomPainter {
  ParticlePainter(this.simulation, Color color)
    : _dotPaint = Paint()
        ..color = color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
      _linePaint = Paint()
        ..color = color.withValues(alpha: 0.25)
        ..strokeWidth = 1,
      super(repaint: simulation);

  final CustomSimulation simulation;
  final Paint _dotPaint;
  final Paint _linePaint;

  @override
  void paint(Canvas canvas, Size size) {
    final lines = Float32List.sublistView(simulation.lines, 0, simulation.lineCount * 4);
    canvas.drawRawPoints(PointMode.lines, lines, _linePaint);
    canvas.drawRawPoints(PointMode.points, simulation.points, _dotPaint);
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.simulation != simulation || oldDelegate._dotPaint.color != _dotPaint.color;
  }
}
