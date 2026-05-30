import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/base_block.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/block_type.dart';
import 'package:wxx_cubia/pages/popstar_game/game/gameplay_scene.dart';

/// ⚡ 问号闪电方块
///
///
///  玩家点击闪电方块会出现一个闪电链消除targetType和targetCount的星星
///
///
///
class LightningBlock extends BaseBlock {
  late LightningCoreComponent lightningCore;
  late TextPainter _textPainter;
  late TextStyle _textStyle;

  final BlockType lightningType;
  BlockType targetType; //目标方块类型
  int targetCount; //目标方块数量
  LightningBlock({
    required super.row,
    required super.col,

    required super.size,
    required this.lightningType,
    required this.targetType,
    this.targetCount = 2,
    super.scene,
  }) : super(blockType: lightningType);

  /// 创建并初始化
  static Future<LightningBlock?> createAndInitialize(
    int row,
    int col,
    GameplayScene scene,
    double blockSize,
    double padding,
    double offsetY,
    BlockType lightningType,
    BlockType targetType,
    int targetCount,
  ) async {
    if (scene.grid[row][col] != null) return null;

    final block = LightningBlock(
      row: row,
      col: col,
      size: Vector2.all(blockSize),
      scene: scene,
      lightningType: lightningType,
      targetType: targetType,
      targetCount: targetCount,
    );

    block.position = Vector2(
      col * (blockSize + padding) + blockSize / 2,
      row * (blockSize + padding) + offsetY + blockSize / 2,
    );

    scene.add(block);
    scene.grid[row][col] = block;

    // 出生强调动画
    block.add(
      ScaleEffect.to(
        Vector2.all(1.25),
        EffectController(duration: 0.3, alternate: true),
      ),
    );

    return block;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    lightningCore = LightningCoreComponent(
      size: Vector2(size.x * 0.8, size.y * 0.85),
      anchor: Anchor.center,
      position: size / 2,
    );

    add(lightningCore);

    _textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // 初始配置文本
    _updateText();
  }

  /// 根据targetType获取对应的颜色
  Color _getTextColorByTargetType() {
    switch (targetType) {
      case BlockType.green_star:
        return Colors.green;
      case BlockType.blue_star:
        return Colors.blue;
      case BlockType.yellow_star:
        return Colors.yellow;
      case BlockType.purple_star:
        return Colors.purple;
      case BlockType.red_star:
        return Colors.red;
      default:
        return Colors.white;
    }
  }

  /// 设置目标方块数量， 闪电的目标方块和类型根据玩家上次消除的星星类型和数量随时更新
  void setTargetCountAndType({required int count, required BlockType type}) {
    targetCount = count;
    targetType = type;
    _updateText();
  }

  /// 更新文本内容
  void _updateText() {
    final text = targetCount > 0 ? '$targetCount' : '?';

    // 初始化文本绘制器
    _textStyle = TextStyle(
      color: _getTextColorByTargetType(),
      fontSize: size.y * 0.4,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          blurRadius: 1.0,
          color: Colors.white.withOpacity(0.9),
          offset: Offset(0.1, 0.1),
        ),
      ],
    );
    _textPainter.text = TextSpan(text: text, style: _textStyle);
    _textPainter.layout(minWidth: 0, maxWidth: size.x);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (highlighted) {
      final rect = Rect.fromLTWH(0, 0, size.x, size.y);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withOpacity(0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(size.x * 0.12)),
        paint,
      );
    }

    // 绘制目标数量文本 - 右上角位置
    final textOffset = Offset(
      size.x - _textPainter.width - size.x * 0.05 - 1, // 右侧内边距
      size.y * 0.05 + 1, // 顶部内边距
    );
    _textPainter.paint(canvas, textOffset);
  }
}

/// ⚡ 闪电核心动画组件
class LightningCoreComponent extends PositionComponent {
  LightningCoreComponent({required super.size, super.position, super.anchor});

  final Random _rand = Random();
  List<Vector2> _points = [];

  double _timer = 0;
  final double _interval = 0.2; // 增加时间间隔以减慢闪电跳动速度

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _generate();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    if (_timer > _interval) {
      _timer = 0;
      _generate();
    }
  }

  void _generate() {
    _points.clear();

    final start = Vector2(size.x * 0.5, size.y * 0.05);
    final end = Vector2(size.x * 0.5, size.y * 0.95);

    _points.add(start);

    const segments = 6;
    final dir = end - start;
    final normal = Vector2(-dir.y, dir.x).normalized();

    for (int i = 1; i < segments; i++) {
      final t = i / segments;
      Vector2 p = start + dir * t;

      p += normal * ((_rand.nextDouble() * 2 - 1) * size.x * 0.28);
      p.x += (_rand.nextDouble() * 2 - 1) * size.x * 0.12;

      _points.add(p);
    }

    _points.add(end);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final glow = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.7)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final core = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < _points.length - 1; i++) {
      canvas.drawLine(_points[i].toOffset(), _points[i + 1].toOffset(), glow);
      canvas.drawLine(_points[i].toOffset(), _points[i + 1].toOffset(), core);
    }
  }
}
