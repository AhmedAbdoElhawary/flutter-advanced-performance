import 'dart:math' show min;

import 'package:flutter/widgets.dart';

extension ScaleContext on BuildContext {
  double get scale => min(1, MediaQuery.sizeOf(this).shortestSide / 720);
}
