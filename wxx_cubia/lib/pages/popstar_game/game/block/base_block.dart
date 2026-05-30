import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/block_type.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/game_block.dart';
import 'package:wxx_cubia/pages/popstar_game/game/gameplay_scene.dart';
import 'package:wxx_cubia/pages/popstar_game/pop_star_game.dart';

class BaseBlock extends GameBlock
    with TapCallbacks, HasGameReference<PopStarGame>, HasVisibility {
  int row; // 行
  int col; // 列

  GameplayScene? scene; //游戏scene

  /// 呼吸动画
  bool _breathe_isAnimating = false;
  double _breathe_animationSpeed = 0.5;
  double _breathe_amplitude = 0.1;
  double _breathe_time = 0;

  /// 有些特殊方块无法用iconSprite的可以用这个
  SpriteComponent? chidSpriteComponent;

  BaseBlock({
    required this.row,
    required this.col,
    required BlockType blockType,
    required Vector2 size,
    Sprite? iconSprite,
    Vector2? position,
    this.scene,
  }) : super(
         position: position ?? Vector2.zero(),
         size: size,
         blockType: blockType,
         icon: iconSprite,
       ) {}

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  /// 开始呼吸动画
  void startPulseAnimation() {
    if (_breathe_isAnimating) return;

    _breathe_isAnimating = true;
    _breathe_time = 0;
  }

  /// 停止动画
  void stopPulseAnimation() {
    if (!_breathe_isAnimating) return;

    _breathe_isAnimating = false;
    _breathe_time = 0;

    scale = Vector2.all(1);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_breathe_isAnimating) {
      _updatePulseAnimation(dt);
    }
  }

  /// 呼吸动画
  void _updatePulseAnimation(double dt) {
    _breathe_time += dt * _breathe_animationSpeed;

    final scaleValue =
        1 + _breathe_amplitude * math.sin(_breathe_time * math.pi * 2);

    scale = Vector2.all(scaleValue);
  }

  /// 呼吸 修改动画参数
  void setAnimationParameters({double? speed, double? amplitude}) {
    if (speed != null) _breathe_animationSpeed = speed;
    if (amplitude != null) _breathe_amplitude = amplitude;
  }

  bool get isAnimating => _breathe_isAnimating;

  /// 点击事件
  @override
  void onTapDown(TapDownEvent event) {
    final currentScene = game.sceneManager.getCurrentScene();

    if (currentScene is GameplayScene) {
      currentScene.handleTap(this);
      return;
    }

    Component? parent = this.parent;

    while (parent != null) {
      if (parent is GameplayScene) {
        parent.handleTap(this);
        break;
      }
      parent = parent.parent;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
  }
}
