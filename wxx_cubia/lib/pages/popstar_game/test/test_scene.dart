import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/block_type.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/cube_block.dart';
import 'package:wxx_cubia/util/huuua_config.dart';
import 'package:wxx_cubia/util_flame/btn/g_text_button.dart';

class TestScene extends PositionComponent with HasGameRef {
  final Function(bool) onStartPressed;
  late final double safeAreaTop;
  bool hasSavedGame = false;

  TestScene({required this.onStartPressed});

  @override
  void onRemove() {
    super.onRemove();
    gameRef.overlays.remove(const_PlayerView);
    gameRef.overlays.remove(const_HomeBanner);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = gameRef.size;
    add(
      GTextButton(
        position: Vector2(size.x / 2, size.y - 50),
        size: Vector2(150, 60), // 方形，圆角会按 size 自动缩放
        text: '返回'.tr,
        textStyle: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.bold,
          height: 1.1,
          letterSpacing: 4.5, // 新增：文字间隔
          color: const Color(0xFFFDF7E6),
        ),
        textScale: 1.0,
        onTap: () {
          onStartPressed(true);
        },
      ),
    );

    final starblock = CubeBlock(
      row: 1,
      col: 1,
      blockType: BlockType.yellow_star,
      size: Vector2(90, 90),
    );
    starblock.position = Vector2(100, 600);
    add(starblock);
  }

  @override
  Future<void> onMount() async {
    super.onMount();
  }
}
