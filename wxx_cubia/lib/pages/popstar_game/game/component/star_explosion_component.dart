import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

class StarExplosionComponent extends ParticleSystemComponent {
  // 共享Random对象，减少对象创建
  static final Random _sharedRandom = Random();

  StarExplosionComponent({required Vector2 position, int totalCount = 80})
    : super(
        position: position,
        particle: Particle.generate(
          count: totalCount,
          generator: (int i) {
            // 使用共享的Random对象
            final random = _sharedRandom;

            // 预计算三角函数，减少重复计算
            final angle = random.nextDouble() * 2 * pi;
            final cosAngle = cos(angle);
            final sinAngle = sin(angle);

            // 初始速度（四散）
            final speed = 100 + random.nextDouble() * 120;
            final velocity = Vector2(cosAngle, sinAngle) * speed;

            // 生命周期
            final lifespan = 2 + random.nextDouble() * 0.8;

            // 初始半径
            final radius = 2.0 + random.nextDouble() * 2.0;

            // 随机多彩颜色 - 预定义颜色数组，避免每次计算HSL
            final color = _getRandomColor(random);

            return GravityParticle(
              velocity: velocity,
              lifespan: lifespan,
              radius: radius,
              color: color,
              initialAngle: angle, // 传递预计算的角度，避免重复计算
            );
          },
        ),
      );

  // 预定义颜色数组，减少计算量
  static Color _getRandomColor(Random random) {
    // 预计算的亮色数组，避免HSL转换开销
    const colors = [
      Color(0xFFFF5252), // 红色
      Color(0xFFFF9800), // 橙色
      Color(0xFFFFEB3B), // 黄色
      Color(0xFF4CAF50), // 绿色
      Color(0xFF2196F3), // 蓝色
      Color(0xFF9C27B0), // 紫色
      Color(0xFFE91E63), // 粉色
      Color(0xFF00BCD4), // 青色
    ];
    return colors[random.nextInt(colors.length)];
  }
}

/// 优化版烟花粒子
class GravityParticle extends Particle {
  final Vector2 velocity;
  final double lifespan;
  final double radius;
  final Color color;
  final double initialAngle; // 预计算的角度

  Vector2 position = Vector2.zero();
  double age = 0;

  // 随机旋转速度，避免每帧计算
  late final double rotationSpeed;

  // 常量：重力加速度 & 阻力系数
  static const double gravity = 300; // 像素/s²
  static const double drag = 0.98; // 阻力（越小减速越快）

  // 缓存Path对象，避免频繁创建
  Path? _cachedStarPath;
  double _cachedRadius = 0.0;

  GravityParticle({
    required this.velocity,
    required this.lifespan,
    required this.radius,
    required this.color,
    required this.initialAngle,
  }) {
    // 随机旋转速度（-π到π）
    final random = Random();
    rotationSpeed = (random.nextDouble() * 2 - 1) * pi * 2;
  }

  @override
  bool get isAlive => age < lifespan;

  @override
  void render(Canvas canvas) {
    final t = age / lifespan; // 0~1
    final fade = 1 - t;

    if (fade <= 0) return; // 完全透明时不渲染

    // 创建Paint对象
    final paint = Paint()..color = color.withOpacity(fade);

    // 计算当前半径
    final currentRadius = radius * (0.7 + (1 - t));

    // 获取或创建缓存的Path
    final path = _getOrCreateStarPath(currentRadius);

    // 绘制
    canvas.save();
    canvas.translate(position.x, position.y);
    canvas.rotate(age * rotationSpeed); // 使用预计算的旋转速度
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  /// 获取或创建缓存的Path
  Path _getOrCreateStarPath(double currentRadius) {
    // 如果缓存为空或半径变化超过0.5，则重新创建Path
    if (_cachedStarPath == null ||
        (_cachedRadius - currentRadius).abs() > 0.5) {
      _cachedStarPath = _createStarPath(currentRadius, 5);
      _cachedRadius = currentRadius;
    }
    return _cachedStarPath!;
  }

  @override
  void update(double dt) {
    age += dt;

    // 更新速度 (重力 + 阻力)
    velocity.y += gravity * dt;
    velocity.x *= drag;
    velocity.y *= drag;

    // 更新位置
    position += velocity * dt;

    // 优化：如果粒子已经基本消失，提前结束生命周期
    if (age > lifespan * 0.9 && velocity.length < 10) {
      age = min(age * 1.1, lifespan);
    }
  }

  /// 画五角星 - 优化版
  Path _createStarPath(double radius, int points) {
    const int pointCount = 5;
    const double innerRatio = 0.5;

    final path = Path();
    final innerRadius = radius * innerRatio;

    // 预计算角度增量
    const double angleIncrement = (2 * pi) / (pointCount * 2);
    const double startAngle = -pi / 2; // 预计算起始角度

    for (int i = 0; i < pointCount * 2; i++) {
      // 交替使用内外半径
      final currentRadius = (i % 2 == 0) ? radius : innerRadius;

      // 计算当前角度
      final double angle = i * angleIncrement + startAngle;

      // 使用预计算的三角函数（如果需要进一步优化）
      final x = currentRadius * cos(angle);
      final y = currentRadius * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    return path;
  }

  /// 可选：更简化的Path创建方法（如果还需要进一步优化）
  Path _createSimplifiedStarPath(double radius) {
    // 创建简单的五角星形状，使用近似计算
    final path = Path();

    // 五角星的5个外点
    for (int i = 0; i < 5; i++) {
      final double angle = i * 72 * pi / 180 - pi / 2;
      final double x = radius * cos(angle);
      final double y = radius * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // 内点
      final double innerAngle = angle + 36 * pi / 180;
      final double innerX = radius * 0.5 * cos(innerAngle);
      final double innerY = radius * 0.5 * sin(innerAngle);
      path.lineTo(innerX, innerY);
    }

    path.close();
    return path;
  }
}
