import 'package:material_ui/material_ui.dart';

import '../scale.dart';
import 'simulation.dart';
import 'simulation_view.dart';

class BenchPage extends StatefulWidget {
  const BenchPage({super.key});

  @override
  State<BenchPage> createState() => _BenchPageState();
}

class _BenchPageState extends State<BenchPage> {
  StorageKind _kind = StorageKind.boxed;
  int _count = 50000;

  /// Only the slider label moves while dragging; the simulation is rebuilt when the drag ends.
  double _sliderValue = 50000;

  @override
  Widget build(BuildContext context) {
    final scale = context.scale;
    final isPhone = MediaQuery.sizeOf(context).shortestSide < 600;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16 * scale, 8 * scale, 16 * scale, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: (isPhone ? 300 : 150) * scale),
              Expanded(
                child: SimulationView(
                  key: ValueKey((_kind, _count)),
                  kind: _kind,
                  count: _count,
                ),
              ),
              SizedBox(height: 16 * scale),
              Row(
                children: [
                  for (final kind in StorageKind.values) ...[
                    if (kind != StorageKind.values.first)
                      SizedBox(width: 8 * scale),
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
              SizedBox(height: 16 * scale),
              Text(
                '${_sliderValue ~/ 1000}K',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24 * scale),
              ),
              Slider(
                value: _sliderValue,
                min: 1000,
                max: 200000,
                divisions: 199,
                onChanged: (value) => setState(() => _sliderValue = value),
                onChangeEnd: (value) => setState(() => _count = value.toInt()),
              ),
            ],
          ),
        ),
      ),
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
    final scale = context.scale;
    final color = selected ? kind.color : const Color(0xFFB8BCC2);

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight(65 * scale),
        foregroundColor: color,
        side: BorderSide(
          color: selected ? kind.color : const Color(0xFF2A2D33),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6 * scale),
        ),
        textStyle: TextStyle(
          fontSize: 30 * scale,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      child: Text(kind.label),
    );
  }
}
