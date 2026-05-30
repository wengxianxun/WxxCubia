import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/sun_flare_component.dart';
import 'package:wxx_cubia/pages/popstar_game/game/manager/game_data_manager.dart';
import 'package:wxx_cubia/util/huuua_config.dart';
import 'package:wxx_cubia/util_flame/btn/g_text_button.dart';
import 'package:wxx_cubia/util_flame/sound_pool.dart';

/// 可点击的按钮组件
class ClaimButtonComponent extends PositionComponent with TapCallbacks {
  final VoidCallback onTap;

  ClaimButtonComponent({
    required Vector2 position,
    required Vector2 size,
    required this.onTap,
  }) : super(position: position, size: size);

  @override
  void onTapUp(TapUpEvent event) {
    onTap();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..color = Colors.green;
    canvas.drawRect(size.toRect(), paint);

    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );
    final tp = TextPainter(
      text: const TextSpan(text: '领取', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(size.x / 2 - tp.width / 2, size.y / 2 - tp.height / 2),
    );
  }
}

/// 盲盒开启动画组件
class BoxOpenAnimation extends PositionComponent with TapCallbacks, HasGameRef {
  final Vector2 startPosition;
  final Vector2 targetPosition;
  final VoidCallback? onComplete;
  final Duration animationDuration;
  final Sprite? boxSprite;
  final Function(ItemType)? onItemClaimed;

  late SpriteComponent _boxSprite;
  SunFlareWithRaysComponent? _sunFlare;
  RectangleComponent? _darkOverlay;

  SpriteComponent? _itemSprite;
  GTextButton? _claimBtn;

  GTextButton? _openBtn;
  ItemType? _currentItem;
  bool _isItemRevealed = false;
  double _progress = 0.0;

  BoxOpenAnimation({
    required this.startPosition,
    required this.targetPosition,
    this.onComplete,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.boxSprite,
    this.onItemClaimed,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // 盲盒
    _boxSprite = SpriteComponent(
      sprite: boxSprite,
      size: Vector2.all(50),
      anchor: Anchor.center,
      position: startPosition,
    );
    add(_boxSprite);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_progress < 1.0) {
      _progress += dt / (animationDuration.inMilliseconds / 1000);
      if (_progress >= 1.0) {
        _progress = 1.0;
        _onArrivedCenter();
      }
      _animateBox();
    }
  }

  void _animateBox() {
    final t = _easeOutCubic(_progress);
    final pos = startPosition + (targetPosition - startPosition) * t;

    final size = 50 + (160 - 50) * t;

    _boxSprite.position = pos;
    _boxSprite.size = Vector2.all(size);
  }

  double _easeOutCubic(double t) {
    double p = 1 - t;
    return 1 - p * p * p;
  }

  /// 到达中心
  void _onArrivedCenter() {
    if (_darkOverlay == null) {
      _darkOverlay = RectangleComponent(
        size: Vector2.all(5000),
        position: Vector2(-2500, -2500),
        paint: Paint()..color = Colors.black.withOpacity(0.5),
      );
      add(_darkOverlay!);
    }

    if (_sunFlare == null) {
      _sunFlare = SunFlareWithRaysComponent(
        rayCount: 12,
        rayLength: 150,
        rayMaxWidth: 25,
        radius: 150,
        opacity: 0.4,
        color: const Color(0xFFFFD700),
        rotationSpeed: 1,
        autoRotate: true,
        position: targetPosition,
      );
      add(_sunFlare!);
    }

    // 盲盒置顶
    _boxSprite.removeFromParent();
    add(_boxSprite);

    _createOpenButton();
    onComplete?.call();
  }

  /// 展示随机道具
  Future<void> _revealItem() async {
    _isItemRevealed = true;

    // 隐藏开箱按钮
    _openBtn?.removeFromParent();

    // 第一步：盲盒果冻动画（缩小放大）
    await _playJellyAnimation();

    // 第二步：爆炸消失效果
    await _playExplosionEffect();

    // 第三步：隐藏盲盒
    _boxSprite.removeFromParent();

    // 第四步：展示随机道具
    final idx = Random().nextInt(ItemType.values.length);
    _currentItem = ItemType.values[idx];

    // 获取道具图片路径
    final imagePath = _getItemImagePath(_currentItem!);

    // 加载道具图片
    final itemImage = await Sprite.load('$imagePath');

    // 创建道具精灵
    _itemSprite = SpriteComponent(
      sprite: itemImage,
      size: Vector2.all(110),
      anchor: Anchor.center,
      position: targetPosition,
    );
    add(_itemSprite!);

    // 领取按钮
    _createClaimButton();
  }

  Future<void> _playJellyAnimation() async {
    final originalSize = _boxSprite.size.clone();

    // 你可以调节 amplitudes 的值控制 Q 弹强度
    final double shrinkScale = 0.82; // 压缩最小比例
    final double overshootScale = 1.15; // 最大弹起比例
    final double reboundScale = 0.94; // 回弹缩小值

    const duration = 0.35;
    double elapsed = 0;

    // 分段比率（可调）
    const shrinkRatio = 0.32; // 缩小阶段 32%
    const overshootRatio = 0.28; // 弹大阶段 28%
    const reboundRatio = 0.22; // 回弹阶段 22%
    const settleRatio = 0.18; // 回到原状 18%

    while (elapsed < duration) {
      final t = elapsed / duration;

      double scale;

      if (t < shrinkRatio) {
        // -------- 1) 慢—渐—缩小 --------
        final p = t / shrinkRatio;
        final eased = 1 - pow(1 - p, 3); // ease-out cubic
        scale = 1 + (shrinkScale - 1) * eased;
      } else if (t < shrinkRatio + overshootRatio) {
        // -------- 2) 快速弹大 --------
        final p = (t - shrinkRatio) / overshootRatio;
        final eased = pow(p, 2); // ease-in 快速
        scale = shrinkScale + (overshootScale - shrinkScale) * eased;
      } else if (t < shrinkRatio + overshootRatio + reboundRatio) {
        // -------- 3) 回弹（变小）--------
        final p = (t - shrinkRatio - overshootRatio) / reboundRatio;
        final eased = 1 - pow(1 - p, 2); // ease-out
        scale = overshootScale + (reboundScale - overshootScale) * eased;
      } else {
        // -------- 4) 回到 1.0 --------
        final p =
            (t - shrinkRatio - overshootRatio - reboundRatio) / settleRatio;
        final eased = pow(p, 2);
        scale = reboundScale + (1 - reboundScale) * eased;
      }

      _boxSprite.size = originalSize * scale;

      elapsed += 1 / 60;
      await Future.delayed(const Duration(milliseconds: 16));
    }

    // 最终归位
    _boxSprite.size = originalSize;
  }

  // ------------------ 缓动 ---------------------
  /// 带急速回弹感（适合弹大）
  double _easeOutBack(double t) {
    const double c1 = 1.70158;
    const double c3 = c1 + 1;

    return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2);
  }

  Future<void> _playExplosionEffect() async {
    final originalSize = _boxSprite.size.clone();
    double elapsed = 0.0;
    const duration = 0.38;

    while (elapsed < duration) {
      final t = elapsed / duration;

      // 缩放爆炸：125% 放大效果
      final scale = 1 + t * 0.25;
      _boxSprite.size = originalSize * scale;

      // 光扩散（透明度下降）
      _boxSprite.opacity = 1 - t;

      elapsed += 1 / 60;
      await Future.delayed(const Duration(milliseconds: 16));
    }

    // 保证彻底透明
    _boxSprite.opacity = 0;
  }

  void _createClaimButton() {
    final btnSize = Vector2(140, 55);
    final btnPos = Vector2(targetPosition.x, targetPosition.y + 200);

    _claimBtn = GTextButton(
      position: btnPos,
      size: btnSize, // 方形，圆角会按 size 自动缩放
      text: 'claim'.tr,
      textStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        height: 1.1,
        letterSpacing: 4.5, // 新增：文字间隔
        color: Colors.white,
      ),
      textScale: 1.0,
      onTap: () async {
        SoundPool().playGetItem();
        _darkOverlay?.removeFromParent();
        _sunFlare?.removeFromParent();
        _claimBtn?.removeFromParent();
        // 先执行飞行动画
        await _flyToButtonItem();

        // 然后删除组件
        removeFromParent();

        if (_currentItem == ItemType.hammer) {
          GameDataManager().addHammerCount(1);
        } else if (_currentItem == ItemType.refresh) {
          GameDataManager().addRefreshCount(1);
        } else if (_currentItem == ItemType.pen) {
          GameDataManager().addPenCount(1);
        }

        if (_currentItem != null && onItemClaimed != null) {
          onItemClaimed!(_currentItem!);
        }
      },
    );
    add(_claimBtn!);
  }

  void _createOpenButton() {
    final btnSize = Vector2(140, 55);
    final btnPos = Vector2(targetPosition.x, targetPosition.y + 200);

    _openBtn = GTextButton(
      position: btnPos,
      size: btnSize, // 方形，圆角会按 size 自动缩放
      text: 'OPEN'.tr,
      textStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        height: 1.1,
        letterSpacing: 4.5, // 新增：文字间隔
        color: const Color(0xFFFDF7E6),
      ),
      textScale: 1.0,
      onTap: () {
        _revealItem();
      },
    );
    add(_openBtn!);
  }

  String _getItemImagePath(ItemType item) {
    switch (item) {
      case ItemType.hammer:
        return 'btn/chuizi.png';
      case ItemType.refresh:
        return 'btn/refresh.png';
      case ItemType.pen:
        return 'btn/pen.png';
    }
  }

  /// 道具飞到对应按钮位置的动画
  Future<void> _flyToButtonItem() async {
    if (_itemSprite == null || _currentItem == null) return;

    // 获取目标按钮位置（基于gameplay_scene.dart中的按钮位置）
    final screenSize = gameRef.size;
    final safeAreaTop = 44.0; // 安全区域顶部
    final buttonY = safeAreaTop + 115; // 按钮Y坐标

    Vector2 targetPosition;
    switch (_currentItem!) {
      case ItemType.hammer:
        // 锤子按钮位置：size.x - 55 - 55, safeAreaTop + 115
        targetPosition = Vector2(screenSize.x - 110, buttonY);
        break;
      case ItemType.refresh:
        // 刷新按钮位置：size.x - 55, safeAreaTop + 115
        targetPosition = Vector2(screenSize.x - 55, buttonY);
        break;
      case ItemType.pen:
        // 改色笔按钮位置：size.x - 55 - 55 - 55, safeAreaTop + 115
        targetPosition = Vector2(screenSize.x - 165, buttonY);
        break;
    }

    // 获取当前位置
    final startPosition = _itemSprite!.position.clone();

    // 飞行动画参数
    const duration = 0.8; // 飞行时间
    const curveHeight = 100.0; // 抛物线高度

    double elapsed = 0.0;

    while (elapsed < duration) {
      final t = elapsed / duration;

      // 使用缓动函数让动画更自然
      final easedT = _easeOutCubic(t);

      // 计算抛物线路径
      final currentX =
          startPosition.x + (targetPosition.x - startPosition.x) * easedT;
      final currentY =
          startPosition.y +
          (targetPosition.y - startPosition.y) * easedT -
          sin(easedT * pi) * curveHeight; // 抛物线效果

      // 更新位置
      _itemSprite!.position = Vector2(currentX, currentY);

      // 逐渐缩小
      final scale = 1.0 - easedT * 0.5; // 缩小到原来的50%
      _itemSprite!.size = Vector2.all(110 * scale);

      // 逐渐透明
      _itemSprite!.opacity = 1.0 - easedT * 0.8; // 保留20%透明度

      elapsed += 1 / 60; // 60 FPS
      await Future.delayed(const Duration(milliseconds: 16));
    }

    // 确保到达目标位置
    _itemSprite!.position = targetPosition;
    _itemSprite!.size = Vector2.all(55); // 最终大小与按钮一致
    _itemSprite!.opacity = 0.2;
  }
}

class MovingParticle extends PositionComponent {
  final Vector2 origin;
  final double angle;
  final double speed;
  final Color color;
  final double lifetime;

  double t = 0.0;
  double opacity = 1.0;
  MovingParticle({
    required this.origin,
    required this.angle,
    required this.speed,
    required this.color,
    required this.lifetime,
  }) : super(
         position: origin.clone(),
         size: Vector2.all(10),
         anchor: Anchor.center,
       );

  @override
  void update(double dt) {
    t += dt;
    if (t >= lifetime) {
      removeFromParent();
      return;
    }

    double p = t / lifetime;

    // 位置
    position = origin + Vector2(cos(angle), sin(angle)) * (speed * p);

    // 缩小
    final s = 10 * (1 - p);
    size = Vector2.all(s);

    // 透明度
    opacity = 1 - p;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, size.x / 2, paint);
  }
}
