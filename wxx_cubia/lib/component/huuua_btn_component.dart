import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:wxx_cubia/component/badge_button.dart';
import 'package:wxx_cubia/pages/popstar_game/game/manager/game_data_manager.dart';

//按钮点击返回类型
enum OnTapType {
  yes("yes", 0), //点击实现成功
  no("no", 0), //点击实现失败
  normal("normal", 0); //点击不处理

  const OnTapType(this.value, this.number);
  final String value;
  final int number;
}

/// 一个带背景和功能图标的按钮组件（支持小红点角标）
class HuuuaBtnComponent extends BadgeButton {
  final String? imagePath;

  final bool Function() onPressed;

  final GameDataManager gameDataManager = GameDataManager();
  late SpriteComponent _icon;
  late RectangleComponent _border;

  // 是否高亮显示
  bool _isHighlighted = false;
  bool get isHighlighted => _isHighlighted;
  set isHighlighted(bool value) {
    _isHighlighted = value;
    _updateBorderVisibility();
  }

  HuuuaBtnComponent({
    this.imagePath,

    required this.onPressed,
    Vector2? position,
    Vector2? size,
    Anchor anchor = Anchor.center,
    required VoidCallback onUpdate,
  }) : super(
         imagePath: imagePath, // 正确传递给父类
         buttonSize: size ?? Vector2(80, 80), // 默认大小
         position: position ?? Vector2.zero(),
         onPressed: () {}, // 我们会覆盖逻辑
         anchor: anchor,
         onUpdate: onUpdate,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 初始角标 - 即使refreshCount为0也显示角标，只是内容为空字符串
    updateBadge();
  }

  // 更新边框可见性
  void _updateBorderVisibility() {
    _border.opacity = _isHighlighted ? 1 : 0;
  }

  @override
  void onMount() {
    super.onMount();
  }

  @override
  void updateBadge() {
    super.updateBadge();
    setBadgeText(
      gameDataManager.refreshCount > 0 ? '${gameDataManager.refreshCount}' : '',
    );
  }
}
