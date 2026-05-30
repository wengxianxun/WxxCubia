import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class LaserBeamComponent extends Component {
  final Vector2 source; // 雷达方块中心
  final Vector2 target; // 目标方块中心
  final double duration; // 激光持续时间
  final Color laserColor; // 激光颜色

  LaserBeamComponent({
    required this.source,
    required this.target,
    this.duration = 0.3,
    this.laserColor = Colors.cyan,
  });

  double _time = 0;
  final Random _rand = Random();

  @override
  void update(double dt) {
    _time += dt;

    // 激光持续时间结束
    if (_time > duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final life = (_time / duration).clamp(0.0, 1.0);

    // 计算宽度：从最大宽度逐渐缩小到0
    final maxWidth = 8.0;
    final width = maxWidth * (1.0 - life);

    // 宽度为0时不再绘制
    if (width <= 0) return;

    // 计算透明度：稍微有点变化
    final alpha = (1.0 - life) * 0.8;

    // 绘制核心激光线
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(alpha * 0.8)
      ..strokeWidth = width * 0.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(source.x, source.y),
      Offset(target.x, target.y),
      corePaint,
    );

    // 绘制外层发光
    final glowPaint = Paint()
      ..color = laserColor.withOpacity(alpha)
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    canvas.drawLine(
      Offset(source.x, source.y),
      Offset(target.x, target.y),
      glowPaint,
    );
  }
}
