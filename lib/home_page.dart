import 'package:flutter/material.dart';

import 'list_vs_flloat64/bench_page.dart';
import 'scale.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = context.scale;

    return Scaffold(
      body: Center(
        child: OutlinedButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BenchPage())),
          style: OutlinedButton.styleFrom(
            minimumSize: Size(0, 65 * scale),
            padding: EdgeInsets.symmetric(horizontal: 24 * scale),
            foregroundColor: const Color(0xFFB8BCC2),
            side: const BorderSide(color: Color(0xFF2A2D33)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6 * scale)),
            textStyle: TextStyle(fontSize: 30 * scale),
          ),
          child: const Text('List VS Float64'),
        ),
      ),
    );
  }
}
