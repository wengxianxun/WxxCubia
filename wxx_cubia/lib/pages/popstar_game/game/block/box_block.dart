import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/base_block.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/block_type.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/sun_flare_component.dart';
import 'package:wxx_cubia/pages/popstar_game/game/gameplay_scene.dart';
import 'package:wxx_cubia/util_flame/sound_pool.dart';

// 盲盒方块
class BoxBlock extends BaseBlock {
  // 用于呼吸边框效果的变量
  double breathOpacity = 1.0;
  bool breathIncreasing = true;
  late TimerComponent breathTimer;

  // 用于彩虹色效果的变量
  double hue = 0.0; // 0-360的色相值
  final double hueSpeed = 2.0; // 色相变化速度

  BoxBlock({
    required super.row,
    required super.col,
    required super.size,
    required Sprite iconSprite,
    required BlockType blockType,
    super.scene,
  }) : super(blockType: blockType, iconSprite: iconSprite) {}

  // 静态工厂方法，用于在指定位置创建并初始化RocketBlock
  static Future<BoxBlock?> createAndInitialize(
    int row,
    int col,
    GameplayScene scene,
    double blockSize,
    double padding,
    double offsetY,
    BlockType blockType, // 添加火箭类型参数
  ) async {
    // 确保位置现在是空的（已被消除）
    if (scene.grid[row][col] != null) {
      return null;
    }

    SoundPool().playNewBlockPopPool();

    // 从场景中获取精灵
    final sprite = scene.sprites[blockType.value];

    if (sprite != null) {
      final boxBlock = BoxBlock(
        row: row,
        col: col,
        iconSprite: sprite,
        size: Vector2.all(blockSize),
        scene: scene,
        blockType: blockType,
      );

      // 设置位置
      boxBlock.position = Vector2(
        col * (blockSize + padding) + blockSize / 2,
        row * (blockSize + padding) + offsetY + blockSize / 2,
      );

      // 添加到场景和网格
      scene.add(boxBlock);
      scene.grid[row][col] = boxBlock;

      boxBlock.add(
        ScaleEffect.to(
          Vector2.all(1.2),
          EffectController(duration: 0.3, alternate: true, repeatCount: 1),
        ),
      );

      return boxBlock;
    }

    return null;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(
      SunFlareWithRaysComponent(
        rayCount: 12,
        rayLength: size.x / 2 * 0.9,
        rayMaxWidth: 4,
        radius: size.x / 2,
        opacity: 0.5,
        position: Vector2(size.x / 2, size.y / 2),
        rotationSpeed: 1.0,
        autoRotate: true,
      ),
    );
    if (icon != null) {
      if (chidSpriteComponent == null) {
        chidSpriteComponent = SpriteComponent(
          sprite: icon,
          size: Vector2(size.x * 0.9, size.y * 0.9),
          position: Vector2.zero(),
          anchor: Anchor.center,
        );
        chidSpriteComponent!.position = Vector2(size.x / 2, size.y / 2);
        add(chidSpriteComponent!);
      }

      chidSpriteComponent!.add(
        ScaleEffect.by(
          Vector2(0.7, 0.7),
          EffectController(
            duration: 1.8,
            alternate: true,
            infinite: true,
            curve: Curves.easeInOut,
          ),
        ),
      );
    }

    breathTimer = TimerComponent(
      period: 0.02,
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
