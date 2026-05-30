import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/block_type.dart';

/// 火箭沿二次贝塞尔曲线飞行 + 尾焰 + 命中爆炸
class RocketArcWithTrail extends PositionComponent with HasGameRef {
  final Vector2 start;
  final Vector2 end;
  final VoidCallback onComplete;
  final double duration;
  final Vector2 control;
  final BlockType rocketType;

  double _elapsed = 0;
  double _angle = 0;

  // 复用的随机数生成器
  final Random _random = Random();

  // 复用的 Paint 对象
  final Paint _glowPaint = Paint()
    ..color = Colors.blueAccent.withOpacity(0.4)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

  // 火箭精灵
  final Sprite? rocketSprite;

  // 火箭类型对应的尾焰颜色映射
  static const Map<BlockType, List<Color>> _rocketTrailColors = {
    BlockType.rocket_blue: [Colors.lightBlue, Colors.blue, Colors.blueAccent],
    BlockType.rocket_red: [Colors.orange, Colors.red, Colors.redAccent],
    BlockType.rocket_purple: [
      Colors.purple,
      Colors.deepPurple,
      Colors.purpleAccent,
    ],
    BlockType.rocket_green: [
      Colors.lightGreen,
      Colors.green,
      Colors.greenAccent,
    ],
    BlockType.rocket_yellow: [Colors.yellow, Colors.amber, Colors.yellowAccent],
  };

  // 默认尾焰颜色（用于非火箭类型）
  static const List<Color> _defaultTrailColors = [
    Colors.yellow,
    Colors.orange,
    Colors.red,
  ];

  // 爆炸颜色列表（复用）
  static const List<Color> _explosionColors = [
    Colors.blueAccent,
    Colors.redAccent,
    Colors.lightBlueAccent,
  ];

  // 获取当前火箭类型对应的尾焰颜色列表
  List<Color> get _currentTrailColors {
    return _rocketTrailColors[rocketType] ?? _defaultTrailColors;
  }

  RocketArcWithTrail({
    required this.start,
    required this.end,
    required this.onComplete,
    required this.rocketType,
    this.duration = 0.8,
    Vector2? control,
    this.rocketSprite,
  }) : control =
           control ??
           Vector2((start.x + end.x) / 2, min(start.y, end.y) - 120) {
    position = start.clone();
    anchor = Anchor.center; // 设置锚点为中心，确保火箭从start位置正确发射
    priority = 100;
  }

  @override
  void onMount() {
    super.onMount();
  }

  /// 二次贝塞尔曲线（优化：使用简单计算避免 pow 调用）
  Vector2 _getBezierPoint(double t) {
    final mt = 1 - t;
    return start * mt * mt + control * 2 * mt * t + end * t * t;
  }

  /// 贝塞尔导数（方向）
  Vector2 _getBezierTangent(double t) {
    final mt = 1 - t;
    return (control - start) * 2 * mt + (end - control) * 2 * t;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    double t = (_elapsed / duration).clamp(0, 1);

    // 更新位置
    position = _getBezierPoint(t);

    // 更新角度
    final tangent = _getBezierTangent(t);
    _angle = atan2(tangent.y, tangent.x);

    // 更频繁地添加尾焰
    if (_elapsed % 0.035 < dt) {
      _addTrail(t);
    }

    if (t >= 1) {
      _triggerExplosion();
      onComplete();
      removeFromParent();
    }
  }

  void _addTrail(double t) {
    // 增加粒子数量：随时间增加，范围从5到15
    final count = 5 + (t * 8).toInt();

    gameRef.add(
      ParticleSystemComponent(
        position: position.clone(),
        particle: Particle.generate(
          count: count,
          lifespan: 0.25, // 增加粒子生命周期
          generator: (i) {
            final velocity = Vector2(
              (_random.nextDouble() - 0.5) * 40,
              50 + _random.nextDouble() * 60,
            );
            return AcceleratedParticle(
              speed: velocity,
              acceleration: Vector2(0, 120),
              child: CircleParticle(
                radius: 1.0 + _random.nextDouble() * 2.0,
                paint: Paint()
                  ..color =
                      _currentTrailColors[_random.nextInt(
                            _currentTrailColors.length,
                          )]
                          .withOpacity(0.8),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 命中时触发爆炸闪光 + 冲击波
  void _triggerExplosion() {
    final impactPos = end.clone();

    // 减少爆炸粒子数量
    gameRef.add(
      ParticleSystemComponent(
        position: impactPos,
        particle: Particle.generate(
          count: 60, // 从80减少到40
          lifespan: 0.4, // 缩短生命周期
          generator: (i) {
            final velocity = Vector2(
              (_random.nextDouble() - 0.5) * 200, // 减小速度范围
              (_random.nextDouble() - 0.5) * 200,
            );
            return AcceleratedParticle(
              speed: velocity,
              acceleration: Vector2(0, 50), // 添加轻微重力
              child: CircleParticle(
                radius: 1.5 + _random.nextDouble() * 2,
                paint: Paint()
                  ..color =
                      _explosionColors[_random.nextInt(_explosionColors.length)]
                          .withOpacity(0.7),
              ),
            );
          },
        ),
      ),
    );

    // 冲击波闪光
    gameRef.add(_ImpactEffect(center: impactPos));
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.rotate(_angle + pi / 2);

    // 光晕效果
    canvas.drawCircle(Offset.zero, 8, _glowPaint);

    // 使用精灵图渲染火箭
    if (rocketSprite != null) {
      rocketSprite!.render(
        canvas,
        position: Vector2(-12, -12), // 精灵大小24x24，需要偏移使其居中
        size: Vector2.all(24),
      );
    } else {
      // 降级处理：使用几何图形绘制
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-3, -10, 6, 20),
          const Radius.circular(3),
        ),
        Paint()..color = Colors.blueAccent,
      );
      canvas.drawCircle(
        const Offset(0, -12),
        4,
        Paint()..color = Colors.orangeAccent,
      );
    }

    canvas.restore();
  }
}

/// 命中冲击波 + 闪光
class _ImpactEffect extends Component {
  final Vector2 center;
  double _elapsed = 0;
  final double duration = 0.4; // 缩短动画时间

  // 复用的 Paint 对象
  final Paint _flashPaint = Paint();
  final Paint _ringPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _glowPaint = Paint()..style = PaintingStyle.stroke;

  _ImpactEffect({required this.center});

  @override
  void render(Canvas canvas) {
    final t = (_elapsed / duration).clamp(0, 1);
    final mt = 1 - t;

    // 白色闪光
    _flashPaint.color = Colors.white.withOpacity(0.5 * mt);
    canvas.drawCircle(center.toOffset(), (30 * mt).toDouble(), _flashPaint);

    // 蓝色冲击波（只保留一层）
    _ringPaint
      ..strokeWidth = (5 * mt).toDouble()
      ..color = Colors.blueAccent.withOpacity(0.6 * mt);
    canvas.drawCircle(center.toOffset(), (15 + 50 * t).toDouble(), _ringPaint);
  }

  @override
  void update(double dt) {
    _elapsed += dt;
    if (_elapsed > duration) removeFromParent();
  }
}
