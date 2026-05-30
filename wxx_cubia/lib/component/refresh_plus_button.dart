import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:wxx_cubia/component/huuua_btn_component.dart';
import 'package:wxx_cubia/util/dialog/item_get_dialog/item_get_dialog.dart';
import 'package:wxx_cubia/util_flame/sound_pool.dart';

/// 刷新添加次数按钮（带次数限制 + 红点角标）
class RefreshPlusButton extends HuuuaBtnComponent {
  // 不再使用本地变量，而是引用GameDataManager中的刷新次数
  final Function() onRefresh;

  // 加号组件
  late TextComponent _plusSign;

  late SpriteComponent _icon2;
  late SpriteComponent _icon3;

  RefreshPlusButton({
    required Vector2 position,
    required this.onRefresh,
    Vector2? size,
    required VoidCallback onUPdate,
  }) : super(
         imagePath: 'btn/refresh.png',
         onPressed: () {
           return true;
         }, // 我们会在onMount中覆盖逻辑
         position: position,
         size: size ?? Vector2(45, 45),
         anchor: Anchor.center,
         onUpdate: onUPdate,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 初始角标 - HuuuaBtnComponent的updateBadge会自动更新角标

    _icon2 = SpriteComponent(
      sprite: await gameRef.loadSprite('btn/chuizi.png'),
      size: size * 0.8, // 比背景小一点
      position: size / 2, // 先定位到中点
      anchor: anchor,
    );
    add(_icon2);

    _icon3 = SpriteComponent(
      sprite: await gameRef.loadSprite('btn/pen.png'),
      size: size * 0.8, // 比背景小一点
      position: size / 2, // 先定位到中点
      anchor: anchor,
    );
    add(_icon3);

    // 添加加号图标到左下角 - 使用自定义的圆角矩形组件
    final _plusBackground = RoundedRectangleShapeComponent(
      size: Vector2(22, 22),
      borderRadius: 8.0,
      color: Colors.green.withOpacity(0.8),
      position: Vector2(0, size.y),
      anchor: Anchor.bottomLeft,
    );
    add(_plusBackground);

    // 创建加号文本组件，使用anchor来居中显示
    _plusSign = TextComponent(
      text: '+',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      // 设置文本位置为背景的中心
      position: Vector2(
        _plusBackground.position.x + _plusBackground.size.x / 2,
        _plusBackground.position.y - _plusBackground.size.y / 2,
      ),
      anchor: Anchor.center, // 设置锚点为中心
    );

    add(_plusSign);
  }

  @override
  void onMount() {
    super.onMount();

    // 按钮点击逻辑
    button.onTap = () {
      // 播放音效
      SoundPool().playButton();
      ItemGetDialog.show(
        onConfirm: () {},
        onCancel: () {},
        // 传递回调函数，用于在领取奖励后刷新按钮显示
        onRewardClaimed: () {
          // 调用updateBadge方法更新显示
          updateBadge();
        },
      );
    };
  }

  // 覆盖父类的updateBadge方法，确保显示正确的刷新次数
  @override
  void updateBadge() {
    // setBadgeText(
    //   gameDataManager.refreshCount > 0
    //       ? '${gameDataManager.refreshCount}'
    //       : '0',
    // );
  }
}

// 添加自定义的圆角矩形ShapeComponent类
class RoundedRectangleShapeComponent extends PositionComponent {
  final double borderRadius;
  final Color color;
  late Paint _paint;

  RoundedRectangleShapeComponent({
    required Vector2 size,
    required this.borderRadius,
    required this.color,
    required Vector2 position,
    required Anchor anchor,
  }) : super(size: size, position: position, anchor: anchor) {
    _paint = Paint()..color = color;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // 创建圆角矩形路径
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.x, size.y),
          Radius.circular(borderRadius),
        ),
      );
    // 绘制圆角矩形
    canvas.drawPath(path, _paint);
  }
}
