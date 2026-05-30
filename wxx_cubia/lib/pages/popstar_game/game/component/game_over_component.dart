import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class GameOverComponent extends PositionComponent {
  final String text;
  final VoidCallback? onComplete;
  final double fontSize;

  late TextComponent _stroke;
  late TextComponent _fill;

  GameOverComponent({
    this.text = 'Game Over!',
    this.onComplete,
    this.fontSize = 55,
    Vector2? position,
  }) : super(position: position ?? Vector2.zero(), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // ✅ 描边层
    _stroke = TextComponent(
      text: text,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..color = Colors.white,
          shadows: const [Shadow(blurRadius: 12, color: Color(0x66FF66CC))],
        ),
      ),
    );

    // ✅ 填充层
    _fill = TextComponent(
      text: text,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: const Color(0xFFFF3366),
          shadows: const [
            Shadow(offset: Offset(2, 2), blurRadius: 6, color: Colors.black38),
          ],
        ),
      ),
    );

    add(_stroke);
    add(_fill);
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
  }
}
