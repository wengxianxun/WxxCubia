import 'dart:math' as math;

import 'package:flame/components.dart' hide Matrix4;
import 'package:flutter/material.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/block_type.dart';

enum BlockShape { circle, diamond, square, triangle, star }

class BlockStyle {
  final Color color;
  final BlockShape shape;
  const BlockStyle({required this.color, required this.shape});
}

const blockStyles = {
  BlockType.red_star: BlockStyle(
    color: Color(0xFFFF4630),
    shape: BlockShape.circle,
  ),
  BlockType.blue_star: BlockStyle(
    color: Color(0xFF2F96D2),
    shape: BlockShape.diamond,
  ),
  BlockType.green_star: BlockStyle(
    color: Color(0xFF6DBE52),
    shape: BlockShape.square,
  ),
  BlockType.yellow_star: BlockStyle(
    color: Color(0xFFFFC93A),
    shape: BlockShape.triangle,
  ),
  BlockType.purple_star: BlockStyle(
    color: Color(0xFFB15CFF),
    shape: BlockShape.star,
  ),
};

const defaultBlockStyle = BlockStyle(
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

  final double _scaleShrinkScale = 0.90;
  final double _scaleAnimationSpeed = 20.0;

  late Rect rect;
  late RRect rrect;

  final Paint bodyPaint = Paint();
  final Paint borderPaint = Paint();
  final Paint shapePaint = Paint();

  Path? _cachedPath;
  BlockShape? _cachedShape;
  double? _cachedSize;

  double? _cachedRadius;
  Offset? _cachedCenter;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    rect = Rect.fromLTWH(1, 1, size.x - 2, size.y - 2);

    rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.x * 0.22));

    _updatePaint();
    _updateCachedShape();
  }

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

  @override
  void update(double dt) {
    super.update(dt);

    _scale += (_scaleTargetScale - _scale) * _scaleAnimationSpeed * dt;

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

  void _updatePaint() {
    final style = blockStyles[blockType] ?? defaultBlockStyle;

    bodyPaint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_lighten(style.color, 0.12), _darken(style.color, 0.18)],
    ).createShader(rect);

    shapePaint.color = _darken(style.color, 0.22);

    borderPaint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withOpacity(.15);
  }

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
    ], size * .12);
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

      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      } else {
        path.lineTo(p1.dx, p1.dy);
      }

      path.quadraticBezierTo(current.dx, current.dy, p2.dx, p2.dy);
    }

    path.close();
    return path;
  }

  Path _createPlumpStarPath(Offset center, double size) {
    final outerRadius = size / 2;
    final innerRadius = outerRadius * .55;

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

  void _drawGlow(Canvas canvas) {
    if (!highlighted) return;

    final glowPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-5, -5, size.x + 10, size.y + 10),
        Radius.circular(size.x * .28),
      ),
      glowPaint,
    );
  }

  void _drawGloss(Canvas canvas) {
    final glossRect = Rect.fromLTWH(
      size.x * .08,
      size.y * .08,
      size.x * .84,
      size.y * .28,
    );

    final glossPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withOpacity(.35), Colors.white.withOpacity(0)],
      ).createShader(glossRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(glossRect, Radius.circular(size.x * .18)),
      glossPaint,
    );
  }

  void _drawCenterShape(Canvas canvas) {
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withOpacity(.18);

    if (_cachedCenter != null &&
        _cachedRadius != null &&
        _cachedShape == BlockShape.circle) {
      canvas.drawCircle(_cachedCenter!, _cachedRadius!, shapePaint);
      canvas.drawCircle(_cachedCenter!, _cachedRadius!, strokePaint);
      return;
    }

    if (_cachedPath != null) {
      canvas.drawPath(_cachedPath!, shapePaint);
      canvas.drawPath(_cachedPath!, strokePaint);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    _drawGlow(canvas);

    canvas.drawRRect(rrect, bodyPaint);

    canvas.drawRRect(rrect, borderPaint);

    _drawGloss(canvas);

    _drawCenterShape(canvas);
  }
}
