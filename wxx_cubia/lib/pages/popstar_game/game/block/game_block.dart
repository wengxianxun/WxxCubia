import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/block_type.dart';

class BlockColorStyle {
  final Color top;
  final Color bottom;
  final Color border;
  final Color shadow; // 👈 新增

  const BlockColorStyle({
    required this.top,
    required this.bottom,
    required this.border,
    required this.shadow,
  });
}

const blockStyles = {
  BlockType.red_star: BlockColorStyle(
    top: Color(0xFFFF4630),
    bottom: Color(0xFFF82A23),
    border: Color(0xFFF82A23),
    shadow: Color(0xFFD81B1B), // 深红
  ),
  BlockType.blue_star: BlockColorStyle(
    top: Color(0xFF2F96D2),
    bottom: Color(0xFF1B78B5),
    border: Color(0xFF1B78B5),
    shadow: Color(0xFF155A8A), // 深蓝
  ),
  BlockType.green_star: BlockColorStyle(
    top: Color(0xFF6DBE52),
    bottom: Color(0xFF4F9B38),
    border: Color(0xFF4F9B38),
    shadow: Color(0xFF3B7A2A), // 深绿
  ),
  BlockType.yellow_star: BlockColorStyle(
    top: Color(0xFFFFC93A),
    bottom: Color(0xFFFFB300),
    border: Color(0xFFFB72FA),
    shadow: Color(0xFFCC8F00), // 深黄（偏橙）
  ),
  BlockType.purple_star: BlockColorStyle(
    top: Color(0xFFB15CFF),
    bottom: Color(0xFF913CFF),
    border: Color(0xFF913CFF),
    shadow: Color(0xFF6F2FCC), // 深紫
  ),
};

const defaultBlockStyle = BlockColorStyle(
  top: Color(0xFF9E9E9E),
  bottom: Color(0xFF6E6E6E),
  border: Color(0xFF5A5A5A),
  shadow: Color(0xFF424242), // 👈 深灰阴影
);

class GameBlock extends PositionComponent {
  GameBlock({required this.blockType, this.icon, super.position, Vector2? size})
    : super(size: size ?? Vector2.all(80), anchor: Anchor.center);

  BlockType blockType;
  Sprite? icon;

  bool highlighted = false;

  /// 缩放动画相关
  double _scale = 1.0;
  double _scale_targetScale = 1.0;
  bool _scale_isAnimating = false;
  bool _scale_shrinkPhase = false;
  final double _scale_shrinkScale = 0.9;
  final double _scale_animationSpeed = 20.0;

  /// ==============================
  /// 缓存对象
  /// ==============================

  late Rect rect;
  late RRect rrect;

  late RRect uprect;

  late Rect innerRect;
  late RRect innerRRect;

  late Rect highlightRect;
  late RRect highlightRRect;

  /// Paint缓存
  final Paint bodyPaint = Paint();

  final Paint upPaint = Paint();

  final Paint borderPaint = Paint();
  final Paint innerBorderPaint = Paint();
  final Paint highlightPaint = Paint();

  @override
  Future<void> onLoad() async {
    super.onLoad();

    /// 主体区域
    rect = Rect.fromLTWH(1, 1, size.x - 2, size.y - 2);

    rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.x * 0.3));

    /// 内边框
    final innerOffset = size.x * 0.0575;

    innerRect = Rect.fromLTWH(
      innerOffset,
      innerOffset,
      size.x - innerOffset * 2,
      size.y - innerOffset * 2,
    );
    uprect = RRect.fromRectAndRadius(innerRect, Radius.circular(size.x * 0.18));
    innerRRect = RRect.fromRectAndRadius(
      innerRect,
      Radius.circular(size.x * (blockType.isStar ? 0.18 : 0.1)),
    );

    /// 高光
    highlightRect = Rect.fromLTWH(
      size.x * 0.2,
      size.y * 0.1,
      size.x * 0.6,
      size.y * 0.35,
    );

    highlightRRect = RRect.fromRectAndRadius(
      highlightRect,
      Radius.circular(size.x * 0.3),
    );

    _updatePaint();
  }

  /// 更新颜色
  void updateTypeAndIcon({required BlockType newType, Sprite? newIcon}) {
    blockType = newType;
    icon = newIcon;

    _updatePaint();
  }

  void setHighlight(bool value) {
    highlighted = value;
    if (highlighted && !_scale_isAnimating) {
      /// 开始动画：先缩小到 0.8
      _scale_isAnimating = true;
      _scale_shrinkPhase = true;
      _scale_targetScale = _scale_shrinkScale;
    } else if (!highlighted) {
      /// 取消高亮，直接恢复到 1.0
      _scale_targetScale = 1.0;
      _scale_isAnimating = false;
      _scale_shrinkPhase = false;
    }
    _updatePaint();
  }

  @override
  void update(double dt) {
    super.update(dt);

    /// 平滑插值到目标缩放
    _scale += (_scale_targetScale - _scale) * _scale_animationSpeed * dt;

    /// 检查是否完成缩小阶段，如果完成则切换到恢复阶段
    if (_scale_isAnimating &&
        _scale_shrinkPhase &&
        (_scale - _scale_shrinkScale).abs() < 0.01) {
      _scale_shrinkPhase = false;
      _scale_targetScale = 1.0;
    }

    /// 检查是否完成恢复阶段
    if (_scale_isAnimating &&
        !_scale_shrinkPhase &&
        (_scale - 1.0).abs() < 0.01) {
      _scale_isAnimating = false;
      _scale = 1.0;
    }

    /// 应用缩放变换
    scale = Vector2.all(_scale);
  }

  /// 更新 Paint
  void _updatePaint() {
    final style = blockStyles[blockType] ?? defaultBlockStyle;

    /// 主体渐变
    bodyPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [style.bottom, style.bottom],
    ).createShader(rect);

    /// 主体上面渐变
    upPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [style.top, style.bottom],
    ).createShader(rect);

    /// 外边框
    borderPaint
      ..color = highlighted ? const Color(0xFFFFE7B8) : style.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.x * 0.0825;

    /// 内边框
    // innerBorderPaint
    //   ..color = style.top.withOpacity(type.isStar ? 0.6 : 0.8)
    //   ..style = PaintingStyle.stroke
    //   ..strokeWidth = 2;

    innerBorderPaint
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        // colors: [
        //   const Color(0xFFFFF3E0).withOpacity(0.2), // 米色（暖高光）
        //   const Color(0xFFFFF3E0).withOpacity(0.2),
        //   highlighted ? style.border : style.shadow, // 清灰（柔阴影）
        // ],
        colors: [
          style.top.withOpacity(0.4), // 高光（同色亮）
          style.shadow.withOpacity(0.4), // 👈 专属阴影
        ],
        stops: const [0.0, 1.0],
      ).createShader(innerRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    /// 高光
    highlightPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        style.top.withOpacity(0.3),
        style.top.withOpacity(0.2),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(highlightRect);
  }

  /// ==============================
  /// 渲染
  /// ==============================

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (blockType.isStar) {
      /// 主体
      // canvas.drawRRect(rrect, bodyPaint);
      //
      // canvas.drawRRect(uprect, upPaint);

      /// 外边框
      canvas.drawRRect(rrect, borderPaint);

      // /// 内边框
      // canvas.drawRRect(innerRRect, innerBorderPaint);
      //
      // /// 高光
      // canvas.drawRRect(highlightRRect, highlightPaint);
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
      final iconSize = size.x * 0.8;

      icon!.render(
        canvas,
        position: Vector2((size.x - iconSize) / 2, (size.y - iconSize) / 2),
        size: Vector2.all(iconSize),
      );
    }
  }
}
