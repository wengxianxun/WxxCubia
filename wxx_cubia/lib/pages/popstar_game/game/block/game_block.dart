import 'dart:math' as math;

import 'package:flame/components.dart' hide Matrix4;
import 'package:flutter/material.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/block_type.dart';

enum BlockShape { circle, diamond, square, triangle, star }

class BlockStyle {
  final Color color;
  final Color top;
  final Color bottom;
  final Color border;
  final Color shadow; // 👈 新增
  final BlockShape shape;
  const BlockStyle({
    required this.color,
    required this.shape,
    required this.top,
    required this.bottom,
    required this.border,
    required this.shadow,
  });
}

const blockStyles = {
  BlockType.red_star: BlockStyle(
    top: Color(0xFFFF4630),
    bottom: Color(0xFFF82A23),
    border: Color(0xFFF82A23),
    shadow: Color(0xFFD81B1B), // 深红
    color: Color(0xFFFF4D5A),
    shape: BlockShape.circle,
  ),
  BlockType.blue_star: BlockStyle(
    top: Color.fromRGBO(87, 183, 246, 1),
    bottom: Color.fromRGBO(0, 96, 187, 1),
    border: Color.fromRGBO(27, 140, 230, 1),
    shadow: Color.fromRGBO(0, 79, 167, 1), // 深蓝
    color: Color(0xFF4DA3FF),
    shape: BlockShape.diamond,
  ),
  BlockType.green_star: BlockStyle(
    top: Color(0xFF6DBE52),
    bottom: Color(0xFF4F9B38),
    border: Color(0xFF4F9B38),
    shadow: Color(0xFF3B7A2A), // 深绿
    color: Color(0xFF55D98A),
    shape: BlockShape.square,
  ),
  BlockType.yellow_star: BlockStyle(
    top: Color(0xFFFFC93A),
    bottom: Color(0xFFFFB300),
    border: Color(0xFFFFB300),
    shadow: Color(0xFFCC8F00), // 深黄（偏橙）
    color: Color(0xFFFFD34D),
    shape: BlockShape.triangle,
  ),
  BlockType.purple_star: BlockStyle(
    top: Color(0xFFB15CFF),
    bottom: Color(0xFF913CFF),
    border: Color(0xFF913CFF),
    shadow: Color(0xFF6F2FCC), // 深紫
    color: Color(0xFFB56CFF),
    shape: BlockShape.star,
  ),
};

const defaultBlockStyle = BlockStyle(
  top: Color(0xFF9E9E9E),
  bottom: Color(0xFF6E6E6E),
  border: Color(0xFF5A5A5A),
  shadow: Color(0xFF424242), // 👈 深灰阴影
  color: Color(0xFF9E9E9E),
  shape: BlockShape.circle,
);

class GameBlock extends PositionComponent {
  GameBlock({required this.blockType, this.icon, super.position, Vector2? size})
    : super(size: size ?? Vector2.all(80), anchor: Anchor.center);

  BlockType blockType;
  Sprite? icon;

  bool highlighted = false;

  double _scale = 1.0;
  double _scaleTargetScale = 1.0;
  bool _scaleIsAnimating = false;
  bool _scaleShrinkPhase = false;

  final double _scaleShrinkScale = 0.92;
  final double _scaleAnimationSpeed = 18.0;

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

  /// 中间元素
  final Paint shapePaint = Paint();
  Path? _cachedPath;
  BlockShape? _cachedShape;
  double? _cachedSize;

  double? _cachedRadius;
  Offset? _cachedCenter;

  // =========================
  // LIFE CYCLE
  // =========================

  @override
  Future<void> onLoad() async {
    await super.onLoad();

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
    _updateCachedShape();
  }

  // =========================
  // PUBLIC API
  // =========================

  void updateTypeAndIcon({required BlockType newType, Sprite? newIcon}) {
    blockType = newType;
    icon = newIcon;
    _updatePaint();
    _updateCachedShape();
  }

  void setHighlight(bool value) {
    highlighted = value;
    if (highlighted && !_scaleIsAnimating) {
      _scaleIsAnimating = true;
      _scaleShrinkPhase = true;
      _scaleTargetScale = _scaleShrinkScale;
    } else if (!highlighted) {
      _scaleTargetScale = 1.0;
      _scaleIsAnimating = false;
      _scaleShrinkPhase = false;
    }
    _updatePaint();
  }

  // =========================
  // UPDATE (保持你原逻辑，仅轻微优化)
  // =========================

  @override
  void update(double dt) {
    super.update(dt);

    final t = (_scaleTargetScale - _scale).abs().clamp(0.0, 1.0);

    _scale +=
        (_scaleTargetScale - _scale) *
        _scaleAnimationSpeed *
        dt *
        _easeOutBack(t);

    if (_scaleIsAnimating &&
        _scaleShrinkPhase &&
        (_scale - _scaleShrinkScale).abs() < 0.01) {
      _scaleShrinkPhase = false;
      _scaleTargetScale = 1.05;
    }

    if (_scaleIsAnimating &&
        !_scaleShrinkPhase &&
        (_scale - 1.05).abs() < 0.02) {
      _scaleTargetScale = 1.0;
    }

    scale = Vector2.all(_scale);
  }

  // =========================
  // MATERIAL SYSTEM（核心升级点）
  // =========================

  void _updatePaint() {
    final style = blockStyles[blockType] ?? defaultBlockStyle;

    /// 主体渐变
    bodyPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [style.border, style.border],
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
      ..strokeWidth = size.x * 0.0625;

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
          Colors.white.withOpacity(0.5),
          Colors.black.withOpacity(0.5),
          // style.top.withOpacity(0.4), // 高光（同色亮）
          // style.bottom.withOpacity(0.4), // 👈 专属阴影
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
    shapePaint.color = _darken(style.color, highlighted ? 0.15 : 0.22);
  }

  // =========================
  // COLOR HELPERS
  // =========================

  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  // =========================
  // SHAPE CACHE（不动你原结构）
  // =========================

  BlockShape getCurrentShape() {
    return (blockStyles[blockType] ?? defaultBlockStyle).shape;
  }

  double _shapeScale(BlockShape shape) {
    switch (shape) {
      case BlockShape.circle:
        return 0.85;
      case BlockShape.square:
        return 0.83;
      case BlockShape.diamond:
        return 0.92;
      case BlockShape.triangle:
        return 1.0;
      case BlockShape.star:
        return 1.05;
    }
  }

  void _updateCachedShape() {
    final shape = getCurrentShape();
    final center = Offset(size.x / 2, size.y / 2);
    final shapeSize = size.x * 0.48 * _shapeScale(shape);

    _cachedShape = shape;
    _cachedSize = shapeSize;
    _cachedCenter = center;

    switch (shape) {
      case BlockShape.circle:
        _cachedRadius = shapeSize / 2;
        _cachedPath = null;
        break;
      case BlockShape.diamond:
        _cachedPath = _createRoundedDiamondPath(center, shapeSize);
        break;
      case BlockShape.square:
        _cachedPath = _createRoundedSquarePath(center, shapeSize);
        break;
      case BlockShape.triangle:
        _cachedPath = _createRoundedTrianglePath(center, shapeSize);
        break;
      case BlockShape.star:
        _cachedPath = _createPlumpStarPath(center, shapeSize);
        break;
    }
  }

  // =========================
  // PATH（保持你的）
  // =========================

  Path _createRoundedDiamondPath(Offset center, double size) {
    final half = size / 2;
    return _roundedPolygonPath([
      Offset(center.dx, center.dy - half),
      Offset(center.dx + half, center.dy),
      Offset(center.dx, center.dy + half),
      Offset(center.dx - half, center.dy),
    ], size * .12);
  }

  Path _createRoundedSquarePath(Offset center, double size) {
    final half = size / 2;
    return _roundedPolygonPath([
      Offset(center.dx - half, center.dy - half),
      Offset(center.dx + half, center.dy - half),
      Offset(center.dx + half, center.dy + half),
      Offset(center.dx - half, center.dy + half),
    ], size * .15);
  }

  Path _createRoundedTrianglePath(Offset center, double size) {
    final half = size / 2;
    final height = size * .866;

    return _roundedPolygonPath([
      Offset(center.dx, center.dy - height / 2),
      Offset(center.dx + half, center.dy + height / 2),
      Offset(center.dx - half, center.dy + height / 2),
    ], size * .18);
  }

  Path _createPlumpStarPath(Offset center, double size) {
    final outerRadius = size / 2;
    final innerRadius = outerRadius * .65;

    final points = <Offset>[];

    for (int i = 0; i < 10; i++) {
      final angle = (i * 36 - 90) * math.pi / 180;
      final radius = i.isEven ? outerRadius : innerRadius;

      points.add(
        Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        ),
      );
    }

    return _roundedPolygonPath(points, size * .06);
  }

  Path _roundedPolygonPath(List<Offset> points, double radius) {
    final path = Path();

    for (int i = 0; i < points.length; i++) {
      final prev = points[(i - 1 + points.length) % points.length];
      final current = points[i];
      final next = points[(i + 1) % points.length];

      final v1 = prev - current;
      final v2 = next - current;

      final d1 = v1.distance;
      final d2 = v2.distance;

      final r = math.min(radius, math.min(d1, d2) * .3);

      final p1 = current + v1 / d1 * r;
      final p2 = current + v2 / d2 * r;

      if (i == 0)
        path.moveTo(p1.dx, p1.dy);
      else
        path.lineTo(p1.dx, p1.dy);

      path.quadraticBezierTo(current.dx, current.dy, p2.dx, p2.dy);
    }

    path.close();
    return path;
  }

  double _easeOutBack(double t) {
    const c1 = 1.70158;
    const c3 = c1 + 1;
    return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2);
  }

  void _drawCenterShape(Canvas canvas) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = Colors.white.withOpacity(.18);

    if (_cachedPath != null) {
      canvas.drawPath(_cachedPath!, shapePaint);
      canvas.drawPath(_cachedPath!, stroke);
    } else if (_cachedRadius != null) {
      canvas.drawCircle(_cachedCenter!, _cachedRadius!, shapePaint);
      canvas.drawCircle(_cachedCenter!, _cachedRadius!, stroke);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    /// 主体
    canvas.drawRRect(rrect, bodyPaint);

    canvas.drawRRect(uprect, upPaint);

    /// 外边框
    canvas.drawRRect(rrect, borderPaint);

    /// 内边框
    canvas.drawRRect(innerRRect, innerBorderPaint);

    /// 高光
    canvas.drawRRect(highlightRRect, highlightPaint);
    _drawCenterShape(canvas);
  }
}
