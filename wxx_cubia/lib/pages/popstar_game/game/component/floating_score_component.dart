import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';

class FloatingScoreComponent extends TextComponent {
  FloatingScoreComponent({
    required Vector2 start,
    required Vector2 end,
    required int score,
    VoidCallback? onArrived,
    double delay = 0.0,
    double? fontSize = 16.0,
  }) : super(
         text: '+$score',
         position: start.clone(),
         anchor: Anchor.center,
         textRenderer: TextPaint(
           style: TextStyle(
             color: const Color(0xFFFFD700),
             fontSize: fontSize,
             fontWeight: FontWeight.bold,
           ),
         ),
       ) {
    add(
      MoveEffect.to(
        end,
        EffectController(
          duration: 0.6,
          startDelay: delay,
          curve: Curves.easeOut,
        ),
        onComplete: () {
          add(
            ScaleEffect.to(
              Vector2.all(0.4),
              EffectController(duration: 0.1, reverseDuration: 0.1),
              onComplete: () {
                onArrived?.call();
                removeFromParent(); // 不再渐隐，直接移除
              },
            ),
          );
        },
      ),
    );
  }
}
