import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 通用角标（类似 App 的红点提示）
/// - 默认红底白字
/// - 宽度根据文字内容自适应
/// - 高度固定，圆角矩形
/// - 支持果冻动画效果
class HuuuaBadge extends PositionComponent with HasGameRef {
  String text;
  final TextStyle textStyle;
  final Paint bgPaint;
  final double badgeHeight;
  late TextPainter _painter;

  // 动画相关属性
  double _scale = 1.0;
  double _animationTime = 0.0;
  bool _isAnimating = false;
  static const Duration _animationDuration = Duration(milliseconds: 600);

  HuuuaBadge({
    required this.text,
    this.textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    ),
    Color bgColor = Colors.red,
    this.badgeHeight = 16.0,
  }) : bgPaint = Paint()..color = bgColor,
       super(anchor: Anchor.topRight) {
    _painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    _updateSize();
  }

  void _updateSize() {
    _painter.text = TextSpan(text: text, style: textStyle);
    _painter.layout();

    final textWidth = _painter.width;
    final double minW = badgeHeight; // 至少是正圆
    final double padding = 8.0; // 左右 padding
    final double w = (textWidth + padding).clamp(minW, 80.0);

    size = Vector2(w, badgeHeight);
  }

  @override
  void render(Canvas canvas) {
    // 保存画布状态
    canvas.save();

    // 应用缩放动画（以中心点为缩放中心）
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    canvas.translate(centerX, centerY);
    canvas.scale(_scale);
    canvas.translate(-centerX, -centerY);

    // 背景圆角矩形
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Radius.circular(size.y / 2),
    );
    canvas.drawRRect(rrect, bgPaint);

    // 绘制文字（居中）
    final dx = (size.x - _painter.width) / 2;
    final dy = (size.y - _painter.height) / 2;
    _painter.paint(canvas, Offset(dx, dy));

    // 恢复画布状态
    canvas.restore();
  }

  /// 更新角标文字
  void setText(String newText) {
    text = newText;
    _updateSize();
    // 触发果冻动画
    startJellyAnimation();
  }

  /// 开始果冻动画
  void startJellyAnimation() {
    _isAnimating = true;
    _animationTime = 0.0;
  }

  /// 果冻缓动函数
  double _jellyEasing(double t) {
    // 模拟果冻效果的缓动函数
    if (t < 0.3) {
      // 先放大
      return 1.0 + (t / 0.3) * 1;
    } else if (t < 0.6) {
      // 再缩小
      return 1.8 - ((t - 0.3) / 0.3) * 0.6;
    } else if (t < 0.8) {
      // 再放大
      return 1.1 + ((t - 0.6) / 0.2) * 0.6;
    } else {
      // 最后回到正常大小
      return 1.4 - ((t - 0.8) / 0.2) * 0.4;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isAnimating) {
      _animationTime += dt;
      final progress =
          _animationTime / _animationDuration.inMilliseconds * 1000;

      if (progress >= 1.0) {
        _scale = 1.0;
        _isAnimating = false;
      } else {
        _scale = _jellyEasing(progress);
      }
    }
  }
}
