import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:wxx_cubia/util/dialog/setting_dialog/setting_dialog.dart';
import 'package:wxx_cubia/util_flame/btn/g_icon_button.dart';
import 'package:wxx_cubia/util_flame/sound_pool.dart';

class SettingButton extends PositionComponent {
  late final GIconButton button;

  SettingButton({required Vector2 position}) {
    button = GIconButton(
      position: position,
      size: Vector2(45, 45),
      icon: Icons.settings, // 使用Material图标
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
  }

  void handlePressed() async {
    SoundPool().playButton();

    SettingDialog.show(
      onConfirm: () {},
      onCancel: () {},
      // 传递回调函数，用于在领取奖励后刷新按钮显示
      onRewardClaimed: () {},
    );
  }
}
