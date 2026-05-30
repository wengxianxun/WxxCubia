import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

class BlueSkillMultiRocket extends Component with HasGameRef {
  final Vector2 start;
  final Vector2 end;
  final Function onComplete;
  final int rocketCount;
  final double duration;

  int _completed = 0;

  BlueSkillMultiRocket({
    required this.start,
    required this.end,
    required this.onComplete,
    this.rocketCount = 5,
    this.duration = 1.3,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();

    for (int i = 0; i < rocketCount; i++) {
      final midX = (start.x + end.x) / 2;
      final midY = min(start.y, end.y) - 140;

      final control = Vector2(
        midX + (i - rocketCount / 2) * 40 + Random().nextDouble() * 20,
        midY - Random().nextDouble() * 50,
      );

      add(
        BlueSkillRocketArc(
          start: start,
          end: end,
          duration: duration + Random().nextDouble() * 0.3,
          control: control,
          onComplete: () {
            _completed++;
            if (_completed >= rocketCount) {
              onComplete();
              removeFromParent();
            }
          },
        ),
      );
    }
  }
}

class BlueSkillRocketArc extends PositionComponent with HasGameRef {
  final Vector2 start;
  final Vector2 end;
  final Function onComplete;
  final double duration;
  final Vector2 control;

  double _elapsed = 0;

  BlueSkillRocketArc({
    required this.start,
    required this.end,
    required this.onComplete,
    required this.control,
    this.duration = 1.3,
  }) {
    position = start.clone();
  }

  /// 二次贝塞尔曲线
  Vector2 _getBezierPoint(double t) {
    return start * pow(1 - t, 2).toDouble() +
        control * 2 * (1 - t) * t +
        end * pow(t, 2).toDouble();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    double t = (_elapsed / duration).clamp(0, 1);

    position = _getBezierPoint(t);

    _addTrail();

    if (t >= 1) {
      onComplete();
      removeFromParent();
    }
  }

  /// 蓝色火箭的粒子尾焰：蓝 → 白 → 淡紫
  void _addTrail() {
    gameRef.add(
      ParticleSystemComponent(
        position: position.clone(),
        particle: Particle.generate(
          count: 4,
          lifespan: 0.35,
          generator: (i) {
            final random = Random();
            final velocity = Vector2(
              (random.nextDouble() - 0.5) * 40,
              60 + random.nextDouble() * 50,
            );
            final colors = [
              Colors.blueAccent,
              Colors.white,
              Colors.purpleAccent.shade100,
            ];
            final color = colors[random.nextInt(colors.length)];
            return AcceleratedParticle(
              speed: velocity,
              acceleration: Vector2(0, 80),
              child: CircleParticle(
                radius: 1.5 + random.nextDouble() * 1.8,
                paint: Paint()..color = color.withOpacity(0.8),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    // 火箭主体（亮蓝）
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.blueAccent, Colors.lightBlueAccent],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 8));

    canvas.drawCircle(Offset.zero, 7, bodyPaint);

    // 火箭头（发光的白色点）
    final headPaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(0, -3), 3, headPaint);
  }
}
