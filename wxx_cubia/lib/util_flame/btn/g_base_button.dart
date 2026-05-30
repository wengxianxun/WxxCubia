// lib/util/btn/g_base_button.dart
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:wxx_cubia/util_flame/sound_pool.dart'; // for Colors

class GBaseButton extends PositionComponent
    with TapCallbacks, HasPaint, HasGameRef {
  void Function()? onTap;
  final double pressedScale;
  bool _pressed = false;

  bool _isSelected = false;

  // 提供getter和setter以便在状态变化时更新UI
  bool get isSelected => _isSelected;

  set isSelected(bool value) {
    if (_isSelected != value) {
      _isSelected = value;
      _updateBorderColors(); // 更新边框颜色
    }
  }

  final Color selectedBorderColor; // 选中状态的边框颜色
  final Color selectedBorderInnerGlowColor;

  // 可配置属性
  final double cornerRadius;
  final double borderThickness;
  final Color borderColor;
  final Color borderInnerGlowColor;
  final Color centerStartColor;
  final Color centerEndColor;
  final double shadowBlur;
  // 新增边框宽度参数
  final double bevelStrokeWidth;
  final double innerRimStrokeWidth;
  final double outerEdgeStrokeWidth;
  final double innerEdgeStrokeWidth;

  final double hilightOrg; //高亮距离

  // 缓存 Paint 对象
  late Paint _outerShadowPaint;
  late Paint _borderPaint;
  late Paint _bevelPaint;
  late Paint _centerPaint;
  late Paint _topHighlightPaint;
  late Paint _innerRimPaint;
  late Paint _outerEdgePaint;
  final VoidCallback? onUpdate;
  GBaseButton({
    super.position,
    super.size,
    super.anchor = Anchor.center,
    this.onTap,
    this.pressedScale = 0.96,
    this.cornerRadius = 20.0,
    this.borderThickness = 8.0,
    this.borderColor = const Color.fromRGBO(247, 156, 49, 1),
    this.selectedBorderColor = const Color.fromRGBO(50, 205, 50, 1), // 默认选中为绿色
    this.selectedBorderInnerGlowColor = const Color(0xFF90EE90), // 默认选中内发光为浅绿色
    this.borderInnerGlowColor = const Color(0xFFFFD54F),
    this.centerStartColor = const Color(0xFF00A7FF),
    this.centerEndColor = const Color(0xFF0077FF),
    this.shadowBlur = 13.0,
    // 新增边框宽度参数，使用默认值与原硬编码值保持一致
    this.bevelStrokeWidth = 2,
    this.innerRimStrokeWidth = 2,
    this.outerEdgeStrokeWidth = 2.0,
    this.innerEdgeStrokeWidth = 3,
    this.hilightOrg = 4,
    this.onUpdate,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 添加 hitbox
    add(RectangleHitbox());

    // 初始化 Paint 对象（缓存）
    _outerShadowPaint = Paint()
      ..color = Colors.redAccent.withOpacity(0.9)
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, shadowBlur);

    // 初始化边框颜色
    _updateBorderColors();
  }

  // 更新边框颜色的方法
  void _updateBorderColors() {
    final effectiveBorderColor = isSelected ? selectedBorderColor : borderColor;
    final effectiveInnerGlowColor = isSelected
        ? selectedBorderInnerGlowColor
        : borderInnerGlowColor;
    _borderPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = ui.Gradient.linear(
        Offset(0, size.y), // 从底部开始
        Offset(0, 0), // 到顶部结束
        [effectiveBorderColor, effectiveInnerGlowColor],
      );

    _bevelPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = bevelStrokeWidth
      ..shader = ui.Gradient.linear(Offset(0, 0), Offset(0, size.y), [
        Colors.white.withOpacity(0.28),
        Colors.white.withOpacity(0.08),
      ]);

    // 修改：中心渐变改为从中下往上
    _centerPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = ui.Gradient.linear(
        Offset(0, size.y - borderThickness), // 从底部开始
        Offset(0, borderThickness), // 到顶部结束
        [centerEndColor, centerStartColor],
      );

    _topHighlightPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = ui.Gradient.linear(
        Offset(0, size.y - borderThickness), // 从底部开始
        Offset(0, borderThickness), // 到顶部结束
        [Colors.white24, Colors.white10],
      );

    _innerRimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = innerRimStrokeWidth
      ..color = Colors.black.withOpacity(0.2);

    // 外褐色描边渐变Paint
    _outerEdgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerEdgeStrokeWidth
      ..shader = ui.Gradient.linear(
        Offset(size.x / 2, 0), // 从顶部中心开始
        Offset(size.x / 2, size.y), // 到底部中心结束
        [
          const Color(0xFFD67726).withOpacity(1), // 顶部不透明
          const Color(0xFFD67726).withOpacity(0.8), // 上部
          const Color(0xFFD67726).withOpacity(0.6), // 中部
          const Color(0xFFD67726).withOpacity(0.5), // 底部较透明
        ],
        [0.0, 0.3, 0.7, 1.0], // 从上到下的颜色停止点
      );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final w = size.x;
    final h = size.y;
    final r = min(cornerRadius, min(w, h) / 2);

    // 外边框（橘色渐变）
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), Radius.circular(r)),
      _borderPaint,
    );

    // 改进的外框褐色描边 - 使用渐变到透明
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), Radius.circular(r)),
      _outerEdgePaint,
    );

    final innerInset = borderThickness;
    final innerRect = Rect.fromLTWH(
      innerInset,
      innerInset,
      w - 2 * innerInset,
      h - 2 * innerInset,
    );
    final innerRadius = max(0, r - innerInset);

    // 内高光
    canvas.drawRRect(
      innerRect.deflate(1.5).toRRect(innerRadius.toDouble()),
      _bevelPaint,
    );

    // 中心渐变
    canvas.drawRRect(innerRect.toRRect(innerRadius.toDouble()), _centerPaint);

    // 内框褐色描边（模拟内阴影）- 也改为渐变效果
    final innerEdgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = innerEdgeStrokeWidth
      ..shader = ui.Gradient.linear(
        Offset(innerRect.center.dx, innerRect.top), // 从中心顶部开始
        Offset(innerRect.center.dx, innerRect.bottom), // 到中心底部结束
        [
          const Color(0xFFD67726).withOpacity(1),
          const Color(0xFFD67726).withOpacity(0.8),
          const Color(0xFFD67726).withOpacity(0.5),
        ],
        [0.0, 0.5, 1.0], // 修正颜色停止点
      );
    canvas.drawRRect(innerRect.toRRect(innerRadius.toDouble()), innerEdgePaint);

    // 上方高光
    final highlightRect = Rect.fromLTWH(
      innerRect.left + hilightOrg,
      innerRect.top + hilightOrg,
      innerRect.width - hilightOrg * 2,
      innerRect.height - hilightOrg * 2,
    );
    canvas.drawRRect(
      highlightRect.toRRect(innerRadius.toDouble()),
      _topHighlightPaint,
    );

    // 新增：白色细线描边增强立体感
    final whiteLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.1
      ..color = Colors.white.withOpacity(0.9);
    canvas.drawRRect(
      highlightRect.toRRect(innerRadius.toDouble()),
      whiteLinePaint,
    );

    // 内侧暗边
    canvas.drawRRect(
      innerRect.deflate(1.5).toRRect(innerRadius - 1.5),
      _innerRimPaint,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    _pressed = true;
    scale = Vector2.all(pressedScale);
  }

  @override
  void onTapUp(TapUpEvent event) {
    _pressed = false;
    scale = Vector2.all(1.0);
    SoundPool().playSelect();
    onTap?.call();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _pressed = false;
    scale = Vector2.all(1.0);
  }
}

extension on Rect {
  RRect toRRect(double radius) =>
      RRect.fromRectAndRadius(this, Radius.circular(radius));
}
