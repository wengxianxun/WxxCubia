import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/block_type.dart';

class BlockColorStyle {
  final Color top;
  final Color bottom;
  final Color border;

  const BlockColorStyle({
    required this.top,
    required this.bottom,
    required this.border,
  });
}

const blockStyles = {
  BlockType.red_star: BlockColorStyle(
    top: Color(0xFFFF4630),
    bottom: Color(0xFFF82A23),
    border: Color(0xFFF82A23),
  ),
  BlockType.blue_star: BlockColorStyle(
    top: Color(0xFF2F96D2),
    bottom: Color(0xFF1B78B5),
    border: Color(0xFF1B78B5),
  ),
  BlockType.green_star: BlockColorStyle(
    top: Color(0xFF6DBE52),
    bottom: Color(0xFF4F9B38),
    border: Color(0xFF4F9B38),
  ),
  BlockType.yellow_star: BlockColorStyle(
    top: Color(0xFFFFC93A),
    bottom: Color(0xFFFFB300),
    border: Color(0xFFFFB300),
  ),
  BlockType.purple_star: BlockColorStyle(
    top: Color(0xFFB15CFF),
    bottom: Color(0xFF913CFF),
    border: Color(0xFF913CFF),
  ),
};

const defaultBlockStyle = BlockColorStyle(
  top: Color(0xFF9E9E9E),
  bottom: Color(0xFF6E6E6E),
  border: Color(0xFF5A5A5A),
);

class CubeflowBlock extends PositionComponent {
  CubeflowBlock({required this.type, this.icon, super.position, Vector2? size})
    : super(size: size ?? Vector2.all(80), anchor: Anchor.center);

  BlockType type;
  Sprite? icon;

  bool highlighted = false;

  /// 缩放动画相关
  double _scale = 1.0;
  double _targetScale = 1.0;
  bool _isAnimating = false;
  bool _shrinkPhase = false;
  final double _shrinkScale = 0.9;
  final double _animationSpeed = 20.0;

  /// ==============================
  /// 缓存对象
  /// ==============================

  late Rect rect;
  late RRect rrect;

  late Rect innerRect;
  late RRect innerRRect;

  late Rect highlightRect;
  late RRect highlightRRect;

  /// Paint缓存
  final Paint bodyPaint = Paint();
  final Paint borderPaint = Paint();
  final Paint innerBorderPaint = Paint();
  final Paint highlightPaint = Paint();

  @override
  Future<void> onLoad() async {
    super.onLoad();

    /// 主体区域
    rect = Rect.fromLTWH(1, 1, size.x - 2, size.y - 2);

    rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.x * 0.12));

    /// 内边框
    final innerOffset = size.x * 0.0575;

    innerRect = Rect.fromLTWH(
      innerOffset,
      innerOffset,
      size.x - innerOffset * 2,
      size.y - innerOffset * 2,
    );

    innerRRect = RRect.fromRectAndRadius(
      innerRect,
      Radius.circular(size.x * (type.isStar ? 0.18 : 0.1)),
    );

    /// 高光
    highlightRect = Rect.fromLTWH(
      size.x * 0.15,
      size.y * 0.1,
      size.x * 0.7,
      size.y * 0.35,
    );

    highlightRRect = RRect.fromRectAndRadius(
      highlightRect,
      Radius.circular(size.x * 0.2),
    );

    _updatePaint();
  }

  /// 更新颜色
  void updateTypeAndIcon({required BlockType newType, Sprite? newIcon}) {
    type = newType;
    icon = newIcon;

    _updatePaint();
  }

  void setHighlight(bool value) {
    highlighted = value;
    if (highlighted && !_isAnimating) {
      /// 开始动画：先缩小到 0.8
      _isAnimating = true;
      _shrinkPhase = true;
      _targetScale = _shrinkScale;
    } else if (!highlighted) {
      /// 取消高亮，直接恢复到 1.0
      _targetScale = 1.0;
      _isAnimating = false;
      _shrinkPhase = false;
    }
    _updatePaint();
  }

  @override
  void update(double dt) {
    super.update(dt);

    /// 平滑插值到目标缩放
    _scale += (_targetScale - _scale) * _animationSpeed * dt;

    /// 检查是否完成缩小阶段，如果完成则切换到恢复阶段
    if (_isAnimating && _shrinkPhase && (_scale - _shrinkScale).abs() < 0.01) {
      _shrinkPhase = false;
      _targetScale = 1.0;
    }

    /// 检查是否完成恢复阶段
    if (_isAnimating && !_shrinkPhase && (_scale - 1.0).abs() < 0.01) {
      _isAnimating = false;
      _scale = 1.0;
    }

    /// 应用缩放变换
    scale = Vector2.all(_scale);
  }

  /// 更新 Paint
  void _updatePaint() {
    final style = blockStyles[type] ?? defaultBlockStyle;

    /// 主体渐变
    bodyPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [style.top, style.bottom],
    ).createShader(rect);

    /// 外边框
    borderPaint
      ..color = highlighted ? const Color(0xFFFFE7B8) : style.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.x * 0.0625;

    /// 内边框
    innerBorderPaint
      ..color = style.top.withOpacity(type.isStar ? 0.6 : 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    /// 高光
    highlightPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.white10, Colors.white10, Colors.transparent],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(highlightRect);
  }

  /// ==============================
  /// 渲染
  /// ==============================

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (type.isStar) {
      /// 主体
      canvas.drawRRect(rrect, bodyPaint);

      /// 外边框
      canvas.drawRRect(rrect, borderPaint);

      /// 内边框
      canvas.drawRRect(innerRRect, innerBorderPaint);

      /// 高光
      canvas.drawRRect(highlightRRect, highlightPaint);
    } else {
      /// 外边框

      /// 能量块主体
      // final specialPaint = Paint()
      //   ..shader = LinearGradient(
      //     begin: Alignment.topCenter,
      //     end: Alignment.bottomCenter,
      //     colors: [const Color(0xFF303030), const Color(0xFF121212)],
      //   ).createShader(rect);
      //
      // canvas.drawRRect(rrect, specialPaint);

      /// glow
      // final glowPaint = Paint()
      //   ..color = Colors.white54
      //   ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      //
      // canvas.drawRRect(rrect.inflate(2), glowPaint);

      /// 边框
      canvas.drawRRect(rrect, borderPaint);

      /// 内边框
      canvas.drawRRect(innerRRect, innerBorderPaint);
    }

    /// icon
    if (icon != null) {
      final iconSize = size.x * 0.86;

      icon!.render(
        canvas,
        position: Vector2((size.x - iconSize) / 2, (size.y - iconSize) / 2),
        size: Vector2.all(iconSize),
      );
    }
  }
}
