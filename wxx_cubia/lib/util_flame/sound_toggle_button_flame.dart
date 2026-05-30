import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:wxx_cubia/util_flame/audio_controller.dart';
import 'package:wxx_cubia/util_flame/btn/g_icon_button.dart';
import 'package:wxx_cubia/util_flame/sound_pool.dart';

class SoundToggleButtonFlame extends PositionComponent {
  late final GIconButton button;

  bool isSoundOn;

  SoundToggleButtonFlame({required Vector2 position})
    : isSoundOn = !AudioController.isMuted {
    button = GIconButton(
      position: position,
      size: Vector2(40, 40),
      icon: isSoundOn
          ? Icons.volume_up_rounded
          : Icons.volume_off_rounded, // 使用Material图标
      iconColor: Colors.black87,
      iconSize: 32.0,
      onTap: handlePressed,
    );

    add(button);
  }

  // 添加update方法来检查声音状态变化
  @override
  void update(double dt) {
    super.update(dt);
    final currentSoundOn = !AudioController.isMuted;
    if (currentSoundOn != isSoundOn) {
      isSoundOn = currentSoundOn;

      button.updateIcon(
        isSoundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
      );
      // button.updateSprite(
      //   isSoundOn ? 'btn/btn_sound_off.png' : 'btn/btn_sound_on.png',
      // );
      // (button.button as SpriteComponent).sprite = isSoundOn
      //     ? soundOnSprite
      //     : soundOffSprite;
    }
  }

  void handlePressed() async {
    SoundPool().playButton();

    if (isSoundOn) {
      await AudioController.mute();
    } else {
      await AudioController.unmute();
    }

    isSoundOn = !isSoundOn;

    button.updateIcon(
      isSoundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
    );
    ;
  }
}
