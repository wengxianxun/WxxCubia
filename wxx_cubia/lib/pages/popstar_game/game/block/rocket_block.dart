import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/base_block.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/block_type.dart';
import 'package:wxx_cubia/pages/popstar_game/game/gameplay_scene.dart';

// 通用火箭方块类，支持多种颜色类型, 火箭方块可以一次性消除所有剩余同颜色的星星
class RocketBlock extends BaseBlock {
  // 用于呼吸边框效果的变量
  double breathOpacity = 1.0;
  bool breathIncreasing = true;
  late TimerComponent breathTimer;

  // 用于彩虹色效果的变量
  double hue = 0.0; // 0-360的色相值
  final double hueSpeed = 2.0; // 色相变化速度

  // 月球旋转组件
  late RotateEffect rotateEffect;

  RocketBlock({
    required super.row,
    required super.col,

    required super.size,
    required Sprite iconSprite,
    required BlockType rocketType, // 添加火箭类型参数
    super.scene,
  }) : super(blockType: rocketType, iconSprite: iconSprite) {}

  // 静态工厂方法，用于在指定位置创建并初始化RocketBlock
  static Future<RocketBlock?> createAndInitialize(
    int row,
    int col,
    GameplayScene scene,
    double blockSize,
    double padding,
    double offsetY,
    BlockType rocketType, // 添加火箭类型参数
  ) async {
    // 确保位置现在是空的（已被消除）
    if (scene.grid[row][col] != null) {
      return null;
    }

    // 从场景中获取精灵
    final sprite = scene.sprites[rocketType.value];

    if (sprite != null) {
      // 创建RocketBlock实例
      final rocketBlock = RocketBlock(
        row: row,
        col: col,

        iconSprite: sprite,
        size: Vector2.all(blockSize),
        scene: scene,
        rocketType: rocketType, // 传入火箭类型
      );

      // 设置位置
      rocketBlock.position = Vector2(
        col * (blockSize + padding) + blockSize / 2,
        row * (blockSize + padding) + offsetY + blockSize / 2,
      );

      // 添加到场景和网格
      scene.add(rocketBlock);
      scene.grid[row][col] = rocketBlock; // 需要类型转换

      // 添加突出显示的视觉效果
      rocketBlock.add(
        ScaleEffect.to(
          Vector2.all(1.2),
          EffectController(duration: 0.3, alternate: true, repeatCount: 1),
        ),
      );

      return rocketBlock;
    }

    return null;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // if (childSprite != null) {
    //   if (chidSpriteComponent == null) {
    //     chidSpriteComponent = SpriteComponent(
    //       sprite: childSprite!,
    //       size: Vector2(size.x * 0.8, size.y * 0.8), // 月球比背景小一点
    //       position: Vector2.zero(),
    //       anchor: Anchor.center,
    //     );
    //     chidSpriteComponent!.position = Vector2(size.x / 2, size.y / 2);
    //     add(chidSpriteComponent!);
    //   }
    //
    //   // 添加轻微缩放动画
    //   chidSpriteComponent!.add(
    //     ScaleEffect.by(
    //       Vector2(0.7, 0.7), // 放大10%
    //       EffectController(
    //         duration: 1.8, // 持续时间1.8秒
    //         alternate: true, // 往返缩放
    //         infinite: true, // 无限循环
    //         curve: Curves.easeInOut, // 缓入缓出效果
    //       ),
    //     ),
    //   );
    // }

    // 添加呼吸动画计时器
    breathTimer = TimerComponent(
      period: 0.02, // 每20毫秒更新一次
      repeat: true,
      onTick: updateBreathEffect,
    );
    add(breathTimer);
  }

  // 更新呼吸效果和彩虹色效果
  void updateBreathEffect() {
    // 更新呼吸透明度
    if (breathIncreasing) {
      breathOpacity += 0.02;
      if (breathOpacity >= 1.0) {
        breathOpacity = 1.0;
        breathIncreasing = false;
      }
    } else {
      breathOpacity -= 0.02;
      if (breathOpacity <= 0.5) {
        breathOpacity = 0.5;
        breathIncreasing = true;
      }
    }

    // 更新彩虹色（色相循环）
    hue += hueSpeed;
    if (hue >= 360.0) {
      hue = 0.0;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // 只绘制边框效果

    // 绘制内层高亮边框
    if (highlighted) {
      // 内层高亮边框保持原有大小
      final innerRect = Rect.fromLTWH(0, 0, size.x, size.y);
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withOpacity(0.8)
        // 添加一点发光效果
        ..maskFilter = MaskFilter.blur(BlurStyle.solid, 1.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(innerRect, Radius.circular(size.x * 0.1)),
        borderPaint,
      );
    }
  }
}
