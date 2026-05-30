import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/base_block.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/block_type.dart';
import 'package:wxx_cubia/pages/popstar_game/game/gameplay_scene.dart';

// 彩虹方块类，继承自BaseBlock
///
///  点击彩虹方块，包括彩虹在内的9宫格方块随机变成同一颜色
///
///
///
class RainbowBlock extends BaseBlock {
  // 彩虹弧组件
  late RainbowArcComponent rainbowArc;

  // 彩虹方块的特殊类型
  final BlockType rainbowType;

  RainbowBlock({
    required super.row,
    required super.col,

    required super.size,
    required this.rainbowType,
    super.scene,
  }) : super(blockType: rainbowType) {}

  // 静态工厂方法，用于在指定位置创建并初始化RainbowBlock
  static Future<RainbowBlock?> createAndInitialize(
    int row,
    int col,
    GameplayScene scene,
    double blockSize,
    double padding,
    double offsetY,
    BlockType rainbowType,
  ) async {
    // 确保位置现在是空的（已被消除）
    if (scene.grid[row][col] != null) {
      return null;
    }

    // 创建RainbowBlock实例
    final rainbowBlock = RainbowBlock(
      row: row,
      col: col,

      size: Vector2.all(blockSize),
      scene: scene,
      rainbowType: rainbowType,
    );

    // 设置位置
    rainbowBlock.position = Vector2(
      col * (blockSize + padding) + blockSize / 2,
      row * (blockSize + padding) + offsetY + blockSize / 2,
    );

    // 添加到场景和网格
    scene.add(rainbowBlock);
    scene.grid[row][col] = rainbowBlock;

    // 添加突出显示的视觉效果
    rainbowBlock.add(
      ScaleEffect.to(
        Vector2.all(1.2),
        EffectController(duration: 0.3, alternate: true, repeatCount: 1),
      ),
    );

    return rainbowBlock;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // 创建彩虹弧组件
    rainbowArc = RainbowArcComponent(
      size: Vector2(size.x * 0.7, size.y * 0.7),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, 4),
    );
    add(rainbowArc);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // 只绘制边框效果

    // 绘制内层高亮边框
    if (highlighted) {
      // 内层高亮边框保持原有大小
      final innerRect = Rect.fromLTWH(0, 0, size.x, size.y);
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withOpacity(0.8)
        // 添加一点发光效果
        ..maskFilter = MaskFilter.blur(BlurStyle.solid, 1.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(innerRect, Radius.circular(size.x * 0.1)),
        borderPaint,
      );
    }
  }
}

// 彩虹弧组件，用于在彩虹方块中显示彩虹效果
class RainbowArcComponent extends PositionComponent with HasGameRef {
  /// 创建一个彩虹弧组件
  ///
  /// [size]: 彩虹的尺寸，x为宽度，y为高度
  /// [position]: 位置坐标
  /// [anchor]: 锚点
  /// [startAngle]: 起始角度（弧度），默认从左上侧开始
  /// [sweepAngle]: 扫过的角度（弧度），默认90度
  /// [colors]: 自定义彩虹颜色，从外到内
  RainbowArcComponent({
    required Vector2 size,
    Vector2? position,
    Anchor anchor = Anchor.topLeft,
    this.startAngle = pi * 0.85,
    this.sweepAngle = pi * 1,
    List<Color>? colors,
  }) : super(size: size, position: position ?? Vector2.zero(), anchor: anchor) {
    _baseColors = colors ?? _rainbowColors;
    _targetColors = _getNextColorSet(_baseColors);
  }

  final double startAngle;
  final double sweepAngle;

  // 基础彩虹颜色
  static const List<Color> _rainbowColors = [
    Color(0xFFFF3B3B), // 红
    Color(0xFFFFA53B), // 橙
    Color(0xFFFFFF3B), // 黄
    Color(0xFF5BFF5B), // 绿
    Color(0xFF5BFFFF), // 青
    Color(0xFF5B5BFF), // 蓝
    Color(0xFFFF5BFF), // 紫
  ];

  // 颜色渐变相关变量
  double _colorTransitionProgress = 0;
  final double _colorTransitionSpeed = 1.0; // 控制渐变速度

  // 基础颜色列表
  late List<Color> _baseColors;
  // 目标颜色列表（下一组要渐变到的颜色）
  late List<Color> _targetColors;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // 初始化目标颜色为基础颜色的循环移位
    _targetColors = _getNextColorSet(_baseColors);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 更新渐变进度
    _colorTransitionProgress += dt * _colorTransitionSpeed;

    // 如果渐变完成，准备下一组颜色
    if (_colorTransitionProgress >= 1.0) {
      _colorTransitionProgress = 0.0;
      _baseColors = List.from(_targetColors);
      _targetColors = _getNextColorSet(_baseColors);
    }
  }

  /// 获取下一组颜色（循环移位）
  List<Color> _getNextColorSet(List<Color> currentColors) {
    if (currentColors.isEmpty) return [];
    return currentColors.sublist(1)..add(currentColors.first);
  }

  /// 在两种颜色之间进行插值
  Color _lerpColor(Color a, Color b, double t) {
    t = _easeInOutQuad(t); // 使用缓动函数使过渡更自然
    return Color.lerp(a, b, t) ?? a;
  }

  /// 缓动函数 - 使颜色过渡更加自然
  double _easeInOutQuad(double t) {
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final w = size.x;
    final h = size.y;

    // 计算圆心位置 - 在组件下方，让彩虹从上方画出
    final center = Offset(w / 2, h * 1.2);

    // 计算半径
    final outerRadius = min(w / 2, h * 1.5);
    final bands = _baseColors.length;
    final totalPadding = outerRadius * 0.05;
    final usableRadius = outerRadius - totalPadding;
    final bandWidth = usableRadius / bands;

    _drawShadow(canvas, center, usableRadius, bandWidth);
    _drawRainbowBands(canvas, center, usableRadius, bandWidth, bands);
    _drawOuterEdge(canvas, center, usableRadius, bandWidth);
    _drawEndCaps(canvas, center, usableRadius, bandWidth);
  }

  /// 绘制阴影
  void _drawShadow(
    Canvas canvas,
    Offset center,
    double usableRadius,
    double bandWidth,
  ) {
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = bandWidth * 1.05;

    final shadowRect = Rect.fromCircle(
      center: center,
      radius: usableRadius - bandWidth / 2,
    );
    canvas.drawArc(shadowRect, startAngle, sweepAngle, false, shadowPaint);
  }

  /// 绘制彩虹色带
  void _drawRainbowBands(
    Canvas canvas,
    Offset center,
    double usableRadius,
    double bandWidth,
    int bands,
  ) {
    for (int i = 0; i < bands; i++) {
      final rOuter = usableRadius - i * bandWidth;
      final rMid = rOuter - bandWidth / 2;

      // 绘制主色带
      _drawMainBand(canvas, center, rMid, i);

      // 绘制高光
      _drawHighlight(canvas, center, rMid, bandWidth);

      // 绘制暗边
      _drawInnerEdge(canvas, center, rMid, bandWidth);
    }
  }

  /// 绘制主色带
  void _drawMainBand(
    Canvas canvas,
    Offset center,
    double radius,
    int bandIndex,
  ) {
    // 使用平滑插值的颜色
    final currentColor = _lerpColor(
      _baseColors[bandIndex],
      _targetColors[bandIndex],
      _colorTransitionProgress,
    );

    // 添加更强的发光效果
    final glowPaint = Paint()
      ..color = currentColor.withOpacity(0.8)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (size.x / _baseColors.length) * 1.2
      ..strokeCap = StrokeCap.round;

    // 主色带
    final paint = Paint()
      ..color = currentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = (size.x / _baseColors.length) * 0.9
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);
    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  /// 绘制高光效果
  void _drawHighlight(
    Canvas canvas,
    Offset center,
    double radius,
    double bandWidth,
  ) {
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, bandWidth * 0.14)
      ..strokeCap = StrokeCap.round;

    final highlightRect = Rect.fromCircle(
      center: center,
      radius: radius - bandWidth * 0.08,
    );

    final highlightStart = startAngle + sweepAngle * 0.1;
    final highlightSweep = sweepAngle * 0.4;
    canvas.drawArc(
      highlightRect,
      highlightStart,
      highlightSweep,
      false,
      highlightPaint,
    );
  }

  /// 绘制内边缘暗边
  void _drawInnerEdge(
    Canvas canvas,
    Offset center,
    double radius,
    double bandWidth,
  ) {
    final innerEdgePaint = Paint()
      ..color = Colors.black.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, bandWidth * 0.08)
      ..strokeCap = StrokeCap.round;

    final innerEdgeRect = Rect.fromCircle(
      center: center,
      radius: radius + bandWidth * 0.08,
    );

    final edgeStart = startAngle + sweepAngle * 0.05;
    final edgeSweep = sweepAngle * 0.5;
    canvas.drawArc(innerEdgeRect, edgeStart, edgeSweep, false, innerEdgePaint);
  }

  /// 绘制外边缘
  void _drawOuterEdge(
    Canvas canvas,
    Offset center,
    double usableRadius,
    double bandWidth,
  ) {
    final outerEdgePaint = Paint()
      ..color = Colors.black.withOpacity(0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(2.0, bandWidth * 0.18)
      ..strokeCap = StrokeCap.round;

    final outerEdgeRect = Rect.fromCircle(
      center: center,
      radius: usableRadius + bandWidth * 0.02,
    );
    canvas.drawArc(
      outerEdgeRect,
      startAngle,
      sweepAngle,
      false,
      outerEdgePaint,
    );
  }

  /// 绘制端点封头
  void _drawEndCaps(
    Canvas canvas,
    Offset center,
    double usableRadius,
    double bandWidth,
  ) {
    final capPaint = Paint()..color = Colors.black.withOpacity(0.12);

    // 计算起点端点
    final startCap = Offset(
      center.dx + cos(startAngle) * usableRadius,
      center.dy + sin(startAngle) * usableRadius,
    );

    // 计算终点端点
    final endCap = Offset(
      center.dx + cos(startAngle + sweepAngle) * usableRadius,
      center.dy + sin(startAngle + sweepAngle) * usableRadius,
    );

    canvas.drawCircle(startCap, bandWidth * 0.55, capPaint);
    canvas.drawCircle(endCap, bandWidth * 0.55, capPaint);
  }

  /// 更新彩虹颜色
  void updateColors(List<Color> newColors) {
    _baseColors = newColors;
    _targetColors = _getNextColorSet(_baseColors);
    _colorTransitionProgress = 0.0; // 重置过渡进度
  }

  /// 设置新的角度
  void updateAngles(double newStartAngle, double newSweepAngle) {
    // 这里可以通过添加效果来实现平滑过渡
    // 目前直接更新
  }
}
