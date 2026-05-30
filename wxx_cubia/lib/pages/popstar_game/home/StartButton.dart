import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class StartButton extends PositionComponent with TapCallbacks {
  final void Function()? onPressed;

  StartButton({required Vector2 position, this.onPressed}) {
    this.position = position;
    size = Vector2(160, 50);
    anchor = Anchor.center;
  }

  @override
  void render(Canvas canvas) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(12),
    );

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.orange, Colors.deepOrange],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));

    canvas.drawRRect(rrect, paint);

    final tp = TextPainter(
      text: const TextSpan(
        text: '开始游戏',
        style: TextStyle(
          fontSize: 20,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(size.x / 2 - tp.width / 2, size.y / 2 - tp.height / 2),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    debugPrint('🎮 游戏开始！');
    onPressed?.call();
  }
}
