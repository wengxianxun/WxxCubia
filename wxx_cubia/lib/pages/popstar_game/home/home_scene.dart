import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wxx_cubia/component/animated_candy_component.dart';
import 'package:wxx_cubia/component/animated_logo_component.dart';
import 'package:wxx_cubia/component/refresh_plus_button.dart';
import 'package:wxx_cubia/pages/popstar_game/game/manager/game_data_manager.dart';
import 'package:wxx_cubia/util/huuua_config.dart';
import 'package:wxx_cubia/util_flame/btn/g_text_button.dart';
import 'package:wxx_cubia/util_flame/setting_button.dart';

class HomeScene extends PositionComponent with HasGameRef {
  final Function(bool) onStartPressed;
  final Function(bool) onTestPressed;
  late final double safeAreaTop;
  bool hasSavedGame = false;

  HomeScene({required this.onStartPressed, required this.onTestPressed});

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

    // 检查是否有保存的游戏
    hasSavedGame = await gameDataManager.hasSavedGame();

    // 然后替换原来的logo代码
    // Logo图
    // final image = await gameRef.images.load('popstarboon.png');
    // add(
    //   SpriteComponent(
    //     sprite: Sprite(image),
    //     size: Vector2(300, 300),
    //     position: Vector2(size.x / 2, size.y / 2 - 100),
    //     anchor: Anchor.center,
    //   ),
    // );

    // 替换为新的动画logo组件
    if (HuuuaConfig.instance.flavorstype == flavors_type.google_candy) {
      add(
        AnimatedCandyComponent(
          size: Vector2(250, 245),
          position: Vector2(size.x / 2, size.y / 2 - 150),
          anchor: Anchor.center,
        ),
      );
    } else {
      add(
        AnimatedLogoComponent(
          size: Vector2(250, 245),
          position: Vector2(size.x / 2, size.y / 2 - 100),
          anchor: Anchor.center,
        ),
      );
    }

    add(
      GTextButton(
        position: Vector2(size.x / 2, size.y / 4 * 3),
        size: Vector2(150, 60), // 方形，圆角会按 size 自动缩放
        text: 'START'.tr,
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

    final refreshButton = RefreshPlusButton(
      position: Vector2(size.x - 100, size.y - 55),
      onUPdate: () {},
      onRefresh: () {},
    );

    add(refreshButton);

    // 如果有保存的游戏，显示继续游戏按钮
    if (hasSavedGame) {
      add(
        GTextButton(
          position: Vector2(size.x / 2, size.y / 4 * 3 + 80),
          size: Vector2(150, 60), // 方形，圆角会按 size 自动缩放
          text: 'CONTINUE'.tr,
          textStyle: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            height: 1.1,
            letterSpacing: 4.5, // 新增：文字间隔
            color: const Color(0xFFFDF7E6),
          ),
          textScale: 1.0,
          onTap: () {
            onStartPressed(false);
          },
        ),
      );
    }

    if (HuuuaConfig.isDebug) {
      add(
        GTextButton(
          position: Vector2(size.x / 2, size.y - 90),
          size: Vector2(150, 60), // 方形，圆角会按 size 自动缩放
          text: 'test'.tr,
          textStyle: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            height: 1.1,
            letterSpacing: 4.5, // 新增：文字间隔
            color: const Color(0xFFFDF7E6),
          ),
          textScale: 1.0,
          onTap: () {
            onTestPressed(true);
          },
        ),
      );
    }

    // 排行榜按钮（Overlay 实现）
    gameRef.overlays.add(const_PlayerView);

    gameRef.overlays.add(const_HomeBanner); //广告

    // add(RedBlock(position: Vector2(200, 600), size: Vector2.all(80)));

    // add(
    //   CandyStarBlock(
    //     topColor: const Color(0xFFFF5A2E),
    //     bottomColor: const Color(0xFFE31700),
    //     icon: await Sprite.load("stars_red.png"),
    //     position: Vector2(200, 700),
    //   ),
    // );

    // add(
    //   GameBlock(
    //     type: BlockType.red_star,
    //     icon: await Sprite.load('star_red.png'),
    //     position: Vector2(200, 500),
    //   ),
    // );
    //
    // add(
    //   GameBlock(
    //     type: BlockType.blue_star,
    //     icon: await Sprite.load('star_blue.png'),
    //     position: Vector2(300, 500),
    //   ),
    // );
    // add(
    //   GameBlock(
    //     type: BlockType.purple_star,
    //     icon: await Sprite.load('star_purple.png'),
    //     position: Vector2(100, 500),
    //   ),
    // );
    //
    // add(
    //   GameBlock(
    //     type: BlockType.yellow_star,
    //     icon: await Sprite.load('star_yellow.png'),
    //     position: Vector2(3, 500),
    //   ),
    // );
    //
    // add(
    //   GameBlock(
    //     type: BlockType.rainbow,
    //     icon: await Sprite.load('star_green.png'),
    //     position: Vector2(3, 600),
    //   ),
    // );

    // final starblock = CubeBlock(
    //   row: 1,
    //   col: 1,
    //   blockType: BlockType.yellow_star,
    //   size: Vector2(90, 90),
    // );
    // starblock.position = Vector2(100, 600);
    // add(starblock);

    // final rainbowBlock = RadarBlock(
    //   row: 1,
    //   col: 1,
    //
    //   size: Vector2(90, 90),
    //   // scene: scene,
    //   blockType: BlockType.radar,
    // );
    //
    // // 设置位置
    // rainbowBlock.position = Vector2(100, 700);
    // add(rainbowBlock);

    // 添加彩虹方块装饰组件（右上角）
    // add(
    //   RainbowArcComponent(
    //     size: Vector2(144, 144), // 调整大小为更合适的尺寸
    //     position: Vector2(100, 333), // 放在右上角，确保在屏幕内
    //   )..priority = 999, // 设置最高优先级确保显示在最上层
    // );
  }

  @override
  Future<void> onMount() async {
    super.onMount();

    // add(
    //   SoundToggleButton(
    //     position: Vector2(size.x - 35, size.y - 55),
    //     // position: Vector2(size.x - 10, size.y - 55),
    //   ),
    // );

    add(
      SettingButton(
        position: Vector2(size.x - 35, size.y - 55),
        // position: Vector2(size.x - 10, size.y - 55),
      ),
    );
  }
}
