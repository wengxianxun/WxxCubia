import 'dart:ui';

import 'package:flame/components.dart';

class StarComponent extends CircleComponent {
  final Color color;

  StarComponent({required this.color})
    : super(radius: 20, paint: Paint()..color = color);

  double angle = 0;

  @override
  void update(double dt) {
    super.update(dt);
    angle += 1.5 * dt;
    angle %= 2 * 3.14159;
    angle = angle; // not used directly; override render
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(radius, radius);
    canvas.rotate(angle);
    canvas.translate(-radius, -radius);
    super.render(canvas);
    canvas.restore();
  }
}
