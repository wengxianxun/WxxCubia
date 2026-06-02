import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class RedBlockComponent extends PositionComponent {
  RedBlockComponent({required Vector2 position, required Vector2 size})
    : super(position: position, size: size);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 建立一个和组件大小相同的矩形画布区域
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    // 圆角半径：根据方块大小自动适配
    final borderRadius = Radius.circular(size.x * 0.25);
    final rrect = RRect.fromRectAndRadius(rect, borderRadius);

    // ----------------------------------------------------
    // 1. 绘制外层圆角方块 (基础颜色)
    // ----------------------------------------------------
    final outerPaint = Paint()
      ..color =
          const Color(0xFFB71C1C) // 基础深红色
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rrect, outerPaint);

    // ----------------------------------------------------
    // 2. 新增：绘制外部边缘高光 (使其具有抛光感)
    // ----------------------------------------------------
    // 我们绘制一个非常薄、几乎透明的白色 RRect，但稍微偏移以模拟特定光源（例如左上角）
    final edgeHighlightPaint = Paint()
      ..color = Colors.white
          .withOpacity(0.5) // 半透明白色
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          size.x *
          0.006 // 非常细的线条
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1); // 柔和的模糊

    // 绘制一个偏上、偏左的高光
    final highlightOffset = Offset(-size.x * 0.005, -size.y * 0.005);
    final highlightRRect = RRect.fromRectAndRadius(
      rect.shift(highlightOffset),
      borderRadius,
    );
    canvas.drawRRect(highlightRRect, edgeHighlightPaint);

    // ----------------------------------------------------
    // 3. 绘制中间圆圈的阴影/高光边框 (凸显立体感)
    // ----------------------------------------------------
    final center = Offset(size.x / 2, size.y / 2);
    final circleRadius = size.x * 0.28; // 圆圈半径约为宽度的 28%

    // 绘制一个稍微偏移的暗色底圈，模拟下方的阴影
    final shadowPaint = Paint()
      ..color = const Color(0xFF7F0000).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.x * 0.04; // 线条粗细

    canvas.drawCircle(
      center.translate(0, size.y * 0.01),
      circleRadius,
      shadowPaint,
    );

    // 绘制一个稍微偏上的亮色底圈，模拟上方的高光
    final centerHighlightPaint = Paint()
      ..color = const Color(0xFFFF8A80).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.x * 0.03;

    canvas.drawCircle(
      center.translate(0, -size.y * 0.005),
      circleRadius,
      centerHighlightPaint,
    );

    // ----------------------------------------------------
    // 4. 绘制中间圆圈的主体面
    // ----------------------------------------------------
    final circlePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.x / 2, size.y * 0.2),
        Offset(size.x / 2, size.y * 0.8),
        [
          const Color(0xFFD32F2F), // 内部圆圈的渐变红
          const Color(0xFFC62828),
        ],
      )
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, circleRadius, circlePaint);
  }
}
