import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class SunFlareWithRaysComponent extends PositionComponent {
  final int rayCount;
  final double rayLength;
  final double rayMaxWidth;
  final double radius; // 中心光晕半径
  final double opacity;
  final Color color;
  final double rotationSpeed; // 旋转速度（弧度/秒）
  final bool autoRotate; // 是否自动旋转

  double _currentRotation = 0.0; // 当前旋转角度

  SunFlareWithRaysComponent({
    this.rayCount = 10,
    this.rayLength = 100,
    this.rayMaxWidth = 38,
    this.radius = 100, // 中心光晕半径
    this.opacity = 0.5,
    this.color = const Color(0xFFFFF176),
    this.rotationSpeed = 1.0, // 默认旋转速度
    this.autoRotate = true, // 默认开启自动旋转
    Vector2? position,
  }) {
    size = Vector2.all((rayLength + radius) * 2);
    anchor = Anchor.center;
    if (position != null) this.position = position;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // 自动旋转
    if (autoRotate) {
      _currentRotation += rotationSpeed * dt;
      // 保持角度在0-2π范围内
      if (_currentRotation > 2 * pi) {
        _currentRotation -= 2 * pi;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = Offset(size.x / 2, size.y / 2);

    // =============================================================
    // 🟡 1. 中心径向渐变光晕（保留）
    // =============================================================
    final radialShader = ui.Gradient.radial(
      center,
      radius,
      [
        color.withOpacity(opacity), // 中心亮
        color.withOpacity(0.0), // 外沿透明
      ],
      [0.0, 1.0],
    );

    final haloPaint = Paint()
      ..shader = radialShader
      ..isAntiAlias = true
      ..blendMode = BlendMode.plus;

    canvas.drawCircle(center, radius, haloPaint);

    // =============================================================
    // 🌟 2. 从中心发射的三角形光线（越远越宽）
    // =============================================================
    for (int i = 0; i < rayCount; i++) {
      final angle = (2 * pi * i) / rayCount + _currentRotation; // 添加当前旋转角度

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      final Path rayPath = Path()
        ..moveTo(0, 0) // 中心点
        ..lineTo(rayLength, -rayMaxWidth / 2) // 左边
        ..lineTo(rayLength, rayMaxWidth / 2) // 右边
        ..close();

      final Paint rayPaint = Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          Offset(rayLength, 0),
          [
            color.withOpacity(0.0), // 中心透明
            color.withOpacity(opacity + 0.1), // 外侧亮
          ],
        )
        ..blendMode = BlendMode.plus
        ..isAntiAlias = true;

      canvas.drawPath(rayPath, rayPaint);
      canvas.restore();
    }
  }
}
