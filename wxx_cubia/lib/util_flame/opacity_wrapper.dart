import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/rendering.dart';

class OpacityWrapper extends PositionComponent implements OpacityProvider {
  @override
  double opacity;

  final Component child;

  OpacityWrapper({required this.child, this.opacity = 1.0});

  @override
  Future<void> onLoad() async {
    await add(child);
  }

  @override
  void render(Canvas canvas) {
    canvas.saveLayer(
      null,
      Paint()..color = const Color(0xFFFFFFFF).withOpacity(opacity),
    );
    super.render(canvas);
    canvas.restore();
  }
}
