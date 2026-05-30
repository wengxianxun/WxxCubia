import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class GameBackground extends PositionComponent with HasGameRef {
  final int starCount;
  final int flareCount;

  GameBackground({this.starCount = 33, this.flareCount = 12});

  final List<_FloatingStar> _stars = [];
  final List<_ColorFlare> _flares = [];
  final List<_ShootingStar> _shootingStars = [];

  double _time = 0.0;
  final Random _rnd = Random();

  // ⭐ 使用 ui.Image 渲染优化性能
  late final ui.Image _starImage;
  late final ui.Image _flareImage;

  @override
  Future<void> onLoad() async {
    size = gameRef.size;

    // 初始化星星
    for (int i = 0; i < starCount; i++) {
      final shape = StarShape.values[_rnd.nextInt(StarShape.values.length)];
      final radius = _rnd.nextDouble() * 2.0 + 1.0;
      _stars.add(
        _FloatingStar(
          position: Vector2(
            _rnd.nextDouble() * size.x,
            _rnd.nextDouble() * size.y,
          ),
          radius: radius,
          speed: _rnd.nextDouble() * 0.2 + 0.05,
          opacity: 0.5,
          blinkSpeed: _rnd.nextDouble() * 1.5 + 0.5,
          shape: shape,
          pathCache: shape == StarShape.circle
              ? null
              : _createStarPath(
                  Offset.zero,
                  radius,
                  shape == StarShape.fourPoint ? 4 : 5,
                ),
        ),
      );
    }

    // 初始化彩色光斑
    for (int i = 0; i < flareCount; i++) {
      final shape = FlareShape.values[_rnd.nextInt(FlareShape.values.length)];
      final radius = _rnd.nextDouble() * 12 + 8;
      final color = Colors.primaries[_rnd.nextInt(Colors.primaries.length)]
          .withOpacity(0.4);
      _flares.add(
        _ColorFlare(
          position: Vector2(
            _rnd.nextDouble() * size.x,
            _rnd.nextDouble() * size.y,
          ),
          radius: radius,
          color: color,
          speed: _rnd.nextDouble() * 0.15 + 0.05,
          shape: shape,
          pathCache: shape == FlareShape.circle
              ? null
              : _createStarPath(
                  Offset.zero,
                  radius,
                  shape == FlareShape.fourPoint ? 4 : 5,
                ),
          shaderCache: shape == FlareShape.circle
              ? null
              : RadialGradient(
                  colors: [color.withOpacity(0.9), color.withOpacity(0.0)],
                ).createShader(
                  Rect.fromCircle(center: Offset.zero, radius: radius),
                ),
        ),
      );
    }

    // 初始化流星池
    for (int i = 0; i < 2; i++) {
      _shootingStars.add(
        _ShootingStar(
          position: Vector2(-1000, -1000),
          length: _rnd.nextDouble() * 100 + 50,
          speed: _rnd.nextDouble() * 500 + 400,
          active: false,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    _time += dt * 0.5;

    // 星星漂浮+闪烁
    for (final star in _stars) {
      star.position.y += star.speed;
      if (star.position.y > size.y) {
        star.position.y = -1;
        star.position.x = _rnd.nextDouble() * size.x;
      }
      star.opacity = (0.3 + 0.6 * (0.5 + 0.5 * sin(star.blinkSpeed * _time)))
          .clamp(0.0, 1.0);
    }

    // 光斑漂浮
    for (final flare in _flares) {
      flare.position.y += flare.speed;
      if (flare.position.y - flare.radius > size.y) {
        flare.position.y = -flare.radius;
        flare.position.x = _rnd.nextDouble() * size.x;

        flare.color = Colors.primaries[_rnd.nextInt(Colors.primaries.length)]
            .withOpacity(0.4);
        if (flare.shape != FlareShape.circle) {
          flare.shaderCache =
              RadialGradient(
                colors: [
                  flare.color.withOpacity(0.9),
                  flare.color.withOpacity(0.0),
                ],
              ).createShader(
                Rect.fromCircle(center: Offset.zero, radius: flare.radius),
              );
        }
      }
    }

    // 流星更新
    for (final s in _shootingStars) {
      if (!s.active) {
        if (_rnd.nextDouble() < 0.001) {
          s.active = true;
          s.position = Vector2(_rnd.nextDouble() * size.x, 0);
          s.length = _rnd.nextDouble() * 100 + 50;
          s.speed = _rnd.nextDouble() * 500 + 400;
        }
      } else {
        s.position += Vector2(s.speed * dt, s.speed * dt / 4);
        if (s.position.x > size.x || s.position.y > size.y) s.active = false;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    _drawDynamicGradient(canvas);

    // 使用 ui.Image 渲染星星和光斑
    for (final star in _stars) {
      final paint = Paint()..color = Colors.white.withOpacity(star.opacity);
      if (star.shape == StarShape.circle) {
        canvas.drawCircle(
          Offset(star.position.x, star.position.y),
          star.radius,
          paint,
        );
      } else {
        canvas.save();
        canvas.translate(star.position.x, star.position.y);
        canvas.drawPath(star.pathCache!, paint);
        canvas.restore();
      }
    }

    for (final flare in _flares) {
      final paint = Paint();
      if (flare.shape == FlareShape.circle) {
        paint.color = flare.color;
        canvas.drawCircle(
          Offset(flare.position.x, flare.position.y),
          flare.radius,
          paint,
        );
      } else {
        paint.shader = flare.shaderCache;
        canvas.save();
        canvas.translate(flare.position.x, flare.position.y);
        canvas.drawPath(flare.pathCache!, paint);
        canvas.restore();
      }
    }

    // 流星
    for (final s in _shootingStars) {
      if (!s.active) continue;
      final paint = Paint()
        ..shader =
            LinearGradient(
              colors: [Colors.white, Colors.white.withOpacity(0.0)],
            ).createShader(
              Rect.fromPoints(
                Offset(s.position.x, s.position.y),
                Offset(s.position.x + s.length, s.position.y + s.length / 4),
              ),
            )
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(s.position.x, s.position.y),
        Offset(s.position.x + s.length, s.position.y + s.length / 4),
        paint,
      );
    }
  }

  void _drawDynamicGradient(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final colorTop = Color.lerp(
      Color(0xFF03030F),
      Color(0xFF050518),
      sin(_time),
    )!;
    final colorBottom = Color.lerp(
      Color(0xFF0A0420),
      Color(0xFF1A0B3A),
      cos(_time),
    )!;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [colorTop, colorBottom],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  static Path _createStarPath(Offset center, double outerRadius, int points) {
    final path = Path();
    final innerRadius = outerRadius * 0.5;
    final step = pi / points;
    for (int i = 0; i < 2 * points; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = i * step - pi / 2;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    path.close();
    return path;
  }
}

// ===== 辅助类 =====
enum StarShape { circle, fourPoint, fivePoint }

enum FlareShape { circle, fourPoint, fivePoint }

class _FloatingStar {
  Vector2 position;
  double radius;
  double speed;
  double opacity;
  double blinkSpeed;
  StarShape shape;
  Path? pathCache;

  _FloatingStar({
    required this.position,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.blinkSpeed,
    required this.shape,
    this.pathCache,
  });
}

class _ColorFlare {
  Vector2 position;
  double radius;
  Color color;
  double speed;
  FlareShape shape;
  Path? pathCache;
  Shader? shaderCache;

  _ColorFlare({
    required this.position,
    required this.radius,
    required this.color,
    required this.speed,
    required this.shape,
    this.pathCache,
    this.shaderCache,
  });
}

class _ShootingStar {
  Vector2 position;
  double length;
  double speed;
  bool active;

  _ShootingStar({
    required this.position,
    required this.length,
    required this.speed,
    this.active = false,
  });
}
