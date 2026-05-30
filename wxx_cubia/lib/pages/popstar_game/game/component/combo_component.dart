import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class ComboTextComponent extends TextComponent {
  ComboTextComponent({required String text, required Vector2 position})
    : super(
        text: text,
        position: position,
        anchor: Anchor.center,
        priority: 1000,
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 42, // 提大一点
            fontWeight: FontWeight.w900,
            color: Colors.orangeAccent, // 比纯黄更高级
            shadows: [
              Shadow(blurRadius: 12, color: Colors.black, offset: Offset(3, 4)),
              Shadow(blurRadius: 20, color: Colors.orange), // 发光感
            ],
          ),
        ),
        // textRenderer: TextPaint(
        //   style: const TextStyle(
        //     fontSize: 36,
        //     fontWeight: FontWeight.w900,
        //     color: Colors.yellow,
        //     shadows: [
        //       Shadow(blurRadius: 8, color: Colors.black, offset: Offset(2, 3)),
        //     ],
        //   ),
        // ),
      );

  @override
  Future<void> onLoad() async {
    scale = Vector2.all(0.6);
    playComboAnimation();
  }

  /// 连击刷新
  void updateCombo(int combo, Vector2 position) {
    text = '$combo COMBO!';
    this.position = position;

    scale = Vector2.all(0.6);
    removeAllEffects();
    playComboAnimation();
  }

  void playComboAnimation() {
    addAll([
      /// 1️⃣ 爆发 Punch
      ScaleEffect.to(
        Vector2.all(1.35),
        EffectController(duration: 0.12, curve: Curves.easeOutBack),
      ),

      /// 2️⃣ 压一下
      ScaleEffect.to(
        Vector2.all(0.95),
        EffectController(
          startDelay: 0.12,
          duration: 0.10,
          curve: Curves.easeIn,
        ),
      ),

      /// 3️⃣ 回稳
      ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(
          startDelay: 0.22,
          duration: 0.10,
          curve: Curves.easeOut,
        ),
      ),

      // /// 4️⃣ 呼吸放大（让 Combo 停留更“活”）
      // ScaleEffect.to(
      //   Vector2.all(1.08),
      //   EffectController(
      //     startDelay: 0.40,
      //     duration: 0.15,
      //     curve: Curves.easeOut,
      //   ),
      // ),
      //
      // /// 5️⃣ 收尾
      // ScaleEffect.to(
      //   Vector2.all(1.0),
      //   EffectController(
      //     startDelay: 0.55,
      //     duration: 0.15,
      //     curve: Curves.easeInOut,
      //   ),
      // ),
    ]);
  }

  void removeAllEffects() {
    for (final child in children.toList()) {
      if (child is Effect) {
        remove(child);
      }
    }
  }
}
