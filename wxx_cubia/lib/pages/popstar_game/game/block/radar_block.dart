import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/base_block.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/block_type.dart';
import 'package:wxx_cubia/pages/popstar_game/game/gameplay_scene.dart';

/// 🛰️ 雷达方块 - 纯雷达扫描效果
class RadarBlock extends BaseBlock {
  late RadarCoreComponent radarCore;
  late TextPainter _textPainter;
  late TextStyle _textStyle;
  bool selected = false;
  int targetCount; //目标方块数量
  RadarBlock({
    required super.row,
    required super.col,

    required super.size,
    required BlockType blockType,
    this.targetCount = 3,
    super.scene,
  }) : super(blockType: blockType);

  static Future<RadarBlock?> createAndInitialize(
    int row,
    int col,
    GameplayScene scene,
    double blockSize,
    double padding,
    double offsetY,
    BlockType blockType,
  ) async {
    if (scene.grid[row][col] != null) return null;

    final block = RadarBlock(
      row: row,
      col: col,

      size: Vector2.all(blockSize),
      scene: scene,
      blockType: blockType,
    );

    block.position = Vector2(
      col * (blockSize + padding) + blockSize / 2,
      row * (blockSize + padding) + offsetY + blockSize / 2,
    );

    scene.add(block);
    scene.grid[row][col] = block;

    return block;
  }

  /// 更新文本内容
  void _updateText() {
    final text = targetCount > 0 ? '$targetCount' : '0';

    // 初始化文本绘制器
    _textStyle = TextStyle(
      color: Colors.white,
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

  // 设置是否高亮选中
  void changeSelected() {
    selected = !selected;
    setHighlight(selected);
    radarCore.setSelected(selected); // 传递给雷达核心
  }

  /// 发出激光，次数减1
  void orderCount() {
    targetCount = targetCount - 1;
    _updateText();
  }

  bool checkCount() {
    if (targetCount <= 0) {
      removeFromParent();
      return true;
    }
    return false;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    radarCore = RadarCoreComponent(
      size: size * 0.9,
      anchor: Anchor.center,
      position: size / 2,
    );

    add(radarCore);

    _textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // 初始配置文本
    _updateText();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 绘制目标数量文本 - 右上角位置
    final textOffset = Offset(
      size.x - _textPainter.width - size.x * 0.05 - 1, // 右侧内边距
      size.y * 0.05 + 1, // 顶部内边距
    );
    _textPainter.paint(canvas, textOffset);
  }
}

class RadarCoreComponent extends PositionComponent {
  RadarCoreComponent({required super.size, super.position, super.anchor});

  // 雷达扫描角度
  double _radarAngle = 0.0;
  // 雷达扫描速度
  final double _radarSpeed = 0.5; // 每秒旋转的圈数
  // 粒子列表
  final List<RadarParticle> _particles = [];
  // 上一次生成粒子的时间
  double _lastParticleTime = 0.0;

  // 呼吸灯效果参数
  bool _selected = false;
  double _breathValue = 0.0; // 0.0 - 1.0
  final double _breathSpeed = 2.0; // 呼吸速度（每秒完成几个周期）
  double _breathDirection = 1.0; // 呼吸方向：1为增加，-1为减少

  // 颜色切换参数
  final List<Color> _colorPalette = [
    Colors.red, // 红色
    Colors.yellow, // 黄色
    Colors.blue, // 蓝色
  ];
  int _currentColorIndex = 0;
  double _colorTransitionTime = 0.0;
  final double _colorChangeInterval = 1.0; // 每种颜色持续2秒
  Color _currentColor = Colors.red;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _currentColor = _colorPalette[0];
  }

  // 设置是否选中
  void setSelected(bool selected) {
    _selected = selected;
    if (!selected) {
      _breathValue = 0.0;
      _breathDirection = 0.5;
      _currentColorIndex = 0;
      _currentColor = _colorPalette[0];
      _colorTransitionTime = 0.0;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 更新雷达扫描角度
    _radarAngle += dt * _radarSpeed * 2 * pi;
    _radarAngle %= 2 * pi;

    // 更新粒子
    _particles.removeWhere((particle) => particle.life <= 0);
    for (final particle in _particles) {
      particle.update(dt);
    }

    // 生成粒子（在扫描线上）
    _lastParticleTime += dt;
    if (_lastParticleTime >= 0.08) {
      // 每0.08秒生成一个粒子
      _lastParticleTime = 0.0;
      _addParticle();
    }

    // 更新呼吸灯效果
    if (_selected) {
      _updateBreathEffect(dt);
      _updateColorTransition(dt);
    }
  }

  void _updateBreathEffect(double dt) {
    // 呼吸效果：使用正弦波
    _breathValue += dt * _breathSpeed * _breathDirection;

    // 在0和1之间来回变化
    if (_breathValue >= 1.0) {
      _breathValue = 1.0;
      _breathDirection = -1.0; // 开始减小
    } else if (_breathValue <= 0.0) {
      _breathValue = 0.0;
      _breathDirection = 1.0; // 开始增加
    }
  }

  void _updateColorTransition(double dt) {
    _colorTransitionTime += dt;

    // 检查是否需要切换颜色
    if (_colorTransitionTime >= _colorChangeInterval) {
      _colorTransitionTime = 0.0;
      _currentColorIndex = (_currentColorIndex + 1) % _colorPalette.length;
      _currentColor = _colorPalette[_currentColorIndex];
    }
  }

  // 根据当前颜色获取渐变色列表
  List<Color> _getGradientColors() {
    switch (_currentColorIndex) {
      case 0: // 红色系
        return [
          Colors.red.withOpacity(0.9),
          Colors.orange.withOpacity(0.7),
          Colors.redAccent.withOpacity(0.5),
        ];
      case 1: // 黄色系
        return [
          Colors.yellow.withOpacity(0.9),
          Colors.amber.withOpacity(0.7),
          Colors.orange.withOpacity(0.5),
        ];
      case 2: // 蓝色系
        return [
          Colors.blue.withOpacity(0.9),
          Colors.lightBlue.withOpacity(0.7),
          Colors.blueAccent.withOpacity(0.5),
        ];
      default:
        return [
          Colors.red.withOpacity(0.9),
          Colors.orange.withOpacity(0.7),
          Colors.redAccent.withOpacity(0.5),
        ];
    }
  }

  // 获取当前颜色的变体
  Color _getLightVariant() {
    switch (_currentColorIndex) {
      case 0:
        return Colors.redAccent;
      case 1:
        return Colors.amberAccent;
      case 2:
        return Colors.lightBlueAccent;
      default:
        return Colors.redAccent;
    }
  }

  Color _getBrightVariant() {
    switch (_currentColorIndex) {
      case 0:
        return const Color(0xFFFF6B6B); // 亮红色
      case 1:
        return const Color(0xFFFFD166); // 亮黄色
      case 2:
        return const Color(0xFF4ECDC4); // 亮青色
      default:
        return const Color(0xFFFF6B6B);
    }
  }

  Color _getDarkVariant() {
    switch (_currentColorIndex) {
      case 0:
        return Colors.red.shade700;
      case 1:
        return Colors.orange.shade700;
      case 2:
        return Colors.blue.shade700;
      default:
        return Colors.red.shade700;
    }
  }

  void _addParticle() {
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x * 0.45;

    // 在扫描线末端生成粒子
    final particleX = center.dx + cos(_radarAngle) * radius;
    final particleY = center.dy + sin(_radarAngle) * radius;

    _particles.add(
      RadarParticle(
        x: particleX,
        y: particleY,
        angle: _radarAngle,
        speed: radius * 0.6, // 向外扩散的速度
        life: 0.7, // 粒子寿命
        size: 2.0,
      ),
    );

    // 在扫描线上随机位置也生成一些粒子
    final randomFactor = Random().nextDouble();
    if (randomFactor < 0.3) {
      final randomDist = Random().nextDouble() * radius;
      final randomX = center.dx + cos(_radarAngle) * randomDist;
      final randomY = center.dy + sin(_radarAngle) * randomDist;

      _particles.add(
        RadarParticle(
          x: randomX,
          y: randomY,
          angle: _radarAngle,
          speed: radius * 0.4,
          life: 0.4,
          size: 1.0,
        ),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x * 0.45;

    // 绘制雷达背景
    _drawRadarBackground(canvas, center, radius);

    // 绘制雷达网格
    _drawRadarGrid(canvas, center, radius);

    // 绘制雷达扫描扇形
    _drawRadarSweep(canvas, center, radius);

    // 绘制粒子
    for (final particle in _particles) {
      particle.render(canvas);
    }

    // 绘制雷达中心（包含呼吸灯效果）
    _drawRadarCenter(canvas, center);

    // 绘制扫描线
    _drawScanLine(canvas, center, radius);
  }

  void _drawRadarBackground(Canvas canvas, Offset center, double radius) {
    // 雷达背景圆盘
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Colors.black.withOpacity(0.1),
          Colors.blueGrey.withOpacity(0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, bgPaint);

    // 外边框
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.cyan.withOpacity(0.3);

    canvas.drawCircle(center, radius, borderPaint);
  }

  void _drawRadarGrid(Canvas canvas, Offset center, double radius) {
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.cyan.withOpacity(0.15);

    // 绘制同心圆网格
    for (int i = 1; i <= 3; i++) {
      final circleRadius = radius * i / 4;
      canvas.drawCircle(center, circleRadius, gridPaint);
    }

    // 绘制十字线
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      gridPaint,
    );

    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      gridPaint,
    );

    // 绘制45度线
    canvas.save();
    canvas.translate(center.dx, center.dy);
    for (int i = 0; i < 4; i++) {
      final angle = pi / 4 * i;
      canvas.drawLine(
        Offset.zero,
        Offset(cos(angle) * radius, sin(angle) * radius),
        gridPaint,
      );
    }
    canvas.restore();
  }

  void _drawRadarSweep(Canvas canvas, Offset center, double radius) {
    // 雷达扫描扇形
    final sweepPath = Path();
    sweepPath.moveTo(center.dx, center.dy);
    sweepPath.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      _radarAngle - pi / 8, // 扇形宽度为22.5度
      pi / 4, // 45度扇形
      false,
    );
    sweepPath.close();

    // 扫描扇形渐变色
    final gradient = SweepGradient(
      center: Alignment.center,
      startAngle: _radarAngle - pi / 8,
      endAngle: _radarAngle + pi / 8,
      colors: [
        Colors.green.withOpacity(0.4),
        Colors.lightGreen.withOpacity(0.6),
        Colors.greenAccent.withOpacity(0.3),
        Colors.transparent,
      ],
      stops: const [0.0, 0.4, 0.8, 1.0],
    );

    final sweepPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(sweepPath, sweepPaint);
  }

  void _drawScanLine(Canvas canvas, Offset center, double radius) {
    // 扫描线
    final lineEndX = center.dx + cos(_radarAngle) * radius;
    final lineEndY = center.dy + sin(_radarAngle) * radius;

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.lightGreenAccent;

    canvas.drawLine(center, Offset(lineEndX, lineEndY), linePaint);

    // 扫描线尖端
    canvas.drawCircle(
      Offset(lineEndX, lineEndY),
      2.5,
      Paint()
        ..color = Colors.greenAccent
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
  }

  void _drawRadarCenter(Canvas canvas, Offset center) {
    final double centerRadius = size.x * 0.08;

    if (_selected) {
      // 选中状态：绘制呼吸灯效果
      _drawBreathingCenter(canvas, center, centerRadius);
    } else {
      // 非选中状态：绘制普通中心
      _drawNormalCenter(canvas, center, centerRadius);
    }
  }

  void _drawNormalCenter(Canvas canvas, Offset center, double baseRadius) {
    // 普通雷达中心圆环
    final rings = [
      Paint()..color = Colors.cyan.withOpacity(0.3),
      Paint()..color = Colors.lightBlue.withOpacity(0.2),
      Paint()..color = Colors.blueAccent.withOpacity(0.1),
    ];

    for (int i = 0; i < rings.length; i++) {
      final ringRadius = baseRadius * 0.5 * (i + 1);
      canvas.drawCircle(center, ringRadius, rings[i]);
    }

    // 中心点
    canvas.drawCircle(
      center,
      baseRadius * 0.25,
      Paint()
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8),
    );
  }

  void _drawBreathingCenter(Canvas canvas, Offset center, double baseRadius) {
    // 计算呼吸效果的半径和透明度
    final breathRadius = baseRadius * (1.0 + _breathValue * 1);
    final breathAlpha = 0.6 + _breathValue * 0.4;
    final pulseAlpha = _breathValue * 0.2;

    // 获取当前颜色的各种变体
    final gradientColors = _getGradientColors();
    final lightVariant = _getLightVariant();
    final brightVariant = _getBrightVariant();
    final darkVariant = _getDarkVariant();

    // 第一层：呼吸光环（最外层）
    canvas.drawCircle(
      center,
      breathRadius * 1.2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = lightVariant.withOpacity(pulseAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
    );

    // 第二层：呼吸光晕
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          gradientColors[0].withOpacity(breathAlpha),
          gradientColors[1].withOpacity(breathAlpha * 0.7),
          gradientColors[2].withOpacity(breathAlpha * 0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: breathRadius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, breathRadius, glowPaint);

    // 第三层：内环（根据呼吸变化）
    final innerRadius = baseRadius * (0.8 + _breathValue * 0.2);
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()..color = darkVariant.withOpacity(0.4 + _breathValue * 0.2),
    );

    // 第四层：核心亮点
    final coreRadius = baseRadius * 0.3;
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            Colors.white.withOpacity(0.9 + _breathValue * 0.1),
            brightVariant.withOpacity(0.7 + _breathValue * 0.2),
            _currentColor.withOpacity(0.8),
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: coreRadius))
        ..style = PaintingStyle.fill,
    );

    // 第五层：最核心的白点
    canvas.drawCircle(
      center,
      baseRadius * 0.15,
      Paint()
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8),
    );

    // 可选：添加微小的跳动粒子
    if (_breathValue > 0.7) {
      final particleCount = 8;
      final particleSize = baseRadius * 0.08 * _breathValue;

      for (int i = 0; i < particleCount; i++) {
        final angle = 2 * pi * i / particleCount + _radarAngle;
        final distance = breathRadius * (0.8 + Random().nextDouble() * 0.2);
        final particleX = center.dx + cos(angle) * distance;
        final particleY = center.dy + sin(angle) * distance;

        canvas.drawCircle(
          Offset(particleX, particleY),
          particleSize,
          Paint()
            ..color = brightVariant.withOpacity(_breathValue * 0.8)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
        );
      }
    }

    // 显示当前颜色的调试信息（可选）
    // _drawColorDebug(canvas, center);
  }

  // 调试用：显示当前颜色信息
  void _drawColorDebug(Canvas canvas, Offset center) {
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );
    final textSpan = TextSpan(
      text: _currentColorIndex == 0
          ? "RED"
          : _currentColorIndex == 1
          ? "YELLOW"
          : "BLUE",
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy + size.x * 0.15),
    );
  }
}

/// 雷达粒子效果
class RadarParticle {
  double x;
  double y;
  double angle;
  double speed;
  double life;
  double maxLife;
  double size;
  Color color;

  RadarParticle({
    required this.x,
    required this.y,
    required this.angle,
    required this.speed,
    required this.life,
    this.size = 1.5,
  }) : maxLife = life,
       color = Colors.greenAccent;

  void update(double dt) {
    // 向外扩散
    x += cos(angle) * speed * dt;
    y += sin(angle) * speed * dt;
    life -= dt;

    // 速度逐渐减慢
    speed *= 0.92;
  }

  void render(Canvas canvas) {
    if (life <= 0) return;

    final alpha = (life / maxLife).clamp(0.0, 1.0);
    final particleRadius = size * alpha;

    // 粒子颜色根据寿命变化
    final particleColor = color.withOpacity(alpha * 0.5);

    canvas.drawCircle(
      Offset(x, y),
      particleRadius,
      Paint()
        ..color = particleColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
    );
  }
}
