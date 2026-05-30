import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:wxx_cubia/pages/popstar_game/game/component/huuua_badge.dart';
import 'package:wxx_cubia/util_flame/btn/g_image_button.dart';

/// 带角标的按钮组件
class BadgeButton extends PositionComponent with HasGameRef {
  final String? imagePath; // 可选
  final Vector2 buttonSize;
  final VoidCallback onPressed;
  final VoidCallback onUpdate;
  late final GImageButton button;
  HuuuaBadge? _badge;

  // 选中状态
  bool _isSelected = false;
  bool get isSelected => _isSelected;
  set isSelected(bool value) {
    _isSelected = value;
    _updateButtonSprite();
  }

  BadgeButton({
    this.imagePath,

    required this.buttonSize,
    required this.onPressed,
    required this.onUpdate,
    Vector2? position,
    Anchor anchor = Anchor.topLeft,
  }) : super(
         position: position ?? Vector2.zero(),
         size: buttonSize,
         anchor: anchor,
       );

  @override
  Future<void> onLoad() async {
    super.onLoad();

    button = GImageButton(
      image: imagePath ?? '',
      onTap: onPressed,
      size: buttonSize,
      anchor: Anchor.topLeft,
    );

    add(button);
  }

  // 更新按钮精灵图片
  Future<void> _updateButtonSprite() async {
    button.isSelected = isSelected;
  }

  void updateBadge() {
    onUpdate();
  }

  /// 设置角标文字（自动显示/隐藏）
  void setBadgeText(String? text) {
    if (text == null || text.isEmpty) {
      _badge?.removeFromParent();
      _badge = null;
      return;
    }

    if (_badge == null) {
      _badge = HuuuaBadge(text: text)
        ..anchor = Anchor.topRight
        ..position = Vector2(buttonSize.x, 0);
      add(_badge!);
      // 新创建的徽章也触发动画
      _badge!.startJellyAnimation();
    } else {
      _badge!.setText(text);
    }
  }
}
