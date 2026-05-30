import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class LightningComponent extends Component {
  final Vector2 start;
  final Vector2 end;
  final double duration;

  LightningComponent({
    required this.start,
    required this.end,
    this.duration = 0.15,
  });

  final Random _rand = Random();

  double _time = 0;

  late List<Vector2> _after;
  late List<Vector2> _main;
  late List<Vector2> _core;

  @override
  Future<void> onLoad() async {
    _regenerate();
  }

  void _regenerate() {
    _after = _build(strength: 1.6);
    _main = _build(strength: 1.0);
    _core = _build(strength: 0.35);
  }

  List<Vector2> _build({required double strength}) {
    final pts = <Vector2>[];

    final dir = end - start;
    final len = dir.length;
    final normal = Vector2(-dir.y, dir.x).normalized();

    const segments = 7;

    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      Vector2 p = start + dir * t;

      /// ✅ 完全对齐 Block 的折叠模型
      final wave = sin(t * pi);
      final fold = wave * len * 0.22 * strength * (_rand.nextDouble() * 2 - 1);

      p += normal * fold;

      // 轻微轴向撕裂（Block 里就有）
      p +=
          dir.normalized() *
          (_rand.nextDouble() * 2 - 1) *
          len *
          0.02 *
          strength;

      pts.add(p);
    }
    return pts;
  }

  @override
  void update(double dt) {
    _time += dt;

    // 只在前半段抖动
    if (_time < duration * 0.45) {
      _main = _build(strength: 1.0);
      _core = _build(strength: 0.35);
    }

    if (_time > duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final life = (_time / duration).clamp(0.0, 1.0);
    final alpha = 1.0 - Curves.easeOut.transform(life);

    _drawAfter(canvas, alpha);
    _drawMain(canvas, alpha);
    _drawCore(canvas, alpha);
  }

  void _drawAfter(Canvas canvas, double a) {
    final paint = Paint()
      // ✅ 偏绿青色，对齐 Block
      ..color = const Color(0xFF6FFFE9).withOpacity(0.68 * a)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    _draw(canvas, _after, paint);
  }

  void _drawMain(Canvas canvas, double a) {
    final paint = Paint()
      ..color = const Color(0xFF2FFFD7).withOpacity(0.85 * a)
      ..strokeWidth = 3.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    _draw(canvas, _main, paint);
  }

  void _drawCore(Canvas canvas, double a) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.95 * a)
      ..strokeWidth = 3.7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _draw(canvas, _core, paint);
  }

  void _draw(Canvas canvas, List<Vector2> pts, Paint paint) {
    if (pts.length < 2) return;

    final path = Path()..moveTo(pts.first.x, pts.first.y);

    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].x, pts[i].y);
    }

    canvas.drawPath(path, paint);
  }
}
