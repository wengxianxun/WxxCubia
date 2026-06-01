// import 'dart:math' as math;
//
// import 'package:flame/components.dart' hide Matrix4;
// import 'package:flutter/material.dart';
// import 'package:wxx_cubia/pages/popstar_game/game/block/block_type.dart';
//
// // 在 GameBlock 类中添加形状枚举
// enum BlockShape {
//   circle, // 圆形
//   diamond, // 菱形
//   square, // 正方形
//   triangle, // 三角形
//   star, //五角星
// }
//
// class BlockStyle {
//   final Color color;
//   final BlockShape shape;
//   const BlockStyle({required this.color, required this.shape});
// }
//
// const blockStyles = {
//   BlockType.red_star: BlockStyle(
//     color: Color(0xFFFF4630),
//     shape: BlockShape.circle,
//   ),
//   BlockType.blue_star: BlockStyle(
//     color: Color(0xFF2F96D2),
//     shape: BlockShape.diamond,
//   ),
//   BlockType.green_star: BlockStyle(
//     color: Color(0xFF6DBE52),
//     shape: BlockShape.square,
//   ),
//   BlockType.yellow_star: BlockStyle(
//     color: Color(0xFFFFC93A),
//     shape: BlockShape.triangle,
//   ),
//   BlockType.purple_star: BlockStyle(
//     color: Color(0xFFB15CFF),
//     shape: BlockShape.star,
//   ),
// };
//
// const defaultBlockStyle = BlockStyle(
//   color: Color(0xFF9E9E9E),
//   shape: BlockShape.circle,
// );
//
// class GameBlock extends PositionComponent {
//   GameBlock({required this.blockType, this.icon, super.position, Vector2? size})
//     : super(size: size ?? Vector2.all(80), anchor: Anchor.center);
//
//   BlockType blockType;
//   Sprite? icon;
//
//   bool highlighted = false;
//
//   /// 缩放动画相关
//   double _scale = 1.0;
//   double _scale_targetScale = 1.0;
//   bool _scale_isAnimating = false;
//   bool _scale_shrinkPhase = false;
//   final double _scale_shrinkScale = 0.9;
//   final double _scale_animationSpeed = 20.0;
//
//   /// ==============================
//   /// 缓存对象
//   /// ==============================
//
//   late Rect rect;
//   late RRect rrect;
//
//   /// Paint缓存
//   final Paint bodyPaint = Paint();
//   final Paint borderPaint = Paint();
//   final Paint shapePaint = Paint();
//
//   /// 缓存形状路径
//   Path? _cachedPath;
//   BlockShape? _cachedShape;
//   double? _cachedSize;
//
//   /// 缓存圆形参数（圆形不需要 Path）
//   double? _cachedRadius;
//   Offset? _cachedCenter;
//
//   @override
//   Future<void> onLoad() async {
//     super.onLoad();
//
//     /// 主体区域
//     rect = Rect.fromLTWH(1, 1, size.x - 2, size.y - 2);
//     rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.x * 0.3));
//
//     _updatePaint();
//     _updateCachedShape(); // 初始化缓存形状
//   }
//
//   /// 更新颜色
//   void updateTypeAndIcon({required BlockType newType, Sprite? newIcon}) {
//     blockType = newType;
//     icon = newIcon;
//
//     _updatePaint();
//     _updateCachedShape(); // 类型改变时更新缓存形状
//   }
//
//   void setHighlight(bool value) {
//     highlighted = value;
//     if (highlighted && !_scale_isAnimating) {
//       /// 开始动画：先缩小到 0.8
//       _scale_isAnimating = true;
//       _scale_shrinkPhase = true;
//       _scale_targetScale = _scale_shrinkScale;
//     } else if (!highlighted) {
//       /// 取消高亮，直接恢复到 1.0
//       _scale_targetScale = 1.0;
//       _scale_isAnimating = false;
//       _scale_shrinkPhase = false;
//     }
//     _updatePaint();
//   }
//
//   @override
//   void update(double dt) {
//     super.update(dt);
//
//     /// 平滑插值到目标缩放
//     _scale += (_scale_targetScale - _scale) * _scale_animationSpeed * dt;
//
//     /// 检查是否完成缩小阶段，如果完成则切换到恢复阶段
//     if (_scale_isAnimating &&
//         _scale_shrinkPhase &&
//         (_scale - _scale_shrinkScale).abs() < 0.01) {
//       _scale_shrinkPhase = false;
//       _scale_targetScale = 1.0;
//     }
//
//     /// 检查是否完成恢复阶段
//     if (_scale_isAnimating &&
//         !_scale_shrinkPhase &&
//         (_scale - 1.0).abs() < 0.01) {
//       _scale_isAnimating = false;
//       _scale = 1.0;
//     }
//
//     /// 应用缩放变换
//     scale = Vector2.all(_scale);
//   }
//
//   /// 更新 Paint
//   void _updatePaint() {
//     final style = blockStyles[blockType] ?? defaultBlockStyle;
//
//     /// 主体渐变
//     bodyPaint.color = style.color;
//
//     /// 形状颜色
//     shapePaint.color = highlighted ? Colors.black : style.color;
//
//     /// 外边框
//     borderPaint
//       ..color = highlighted ? style.color : style.color
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = size.x * 0.0825;
//   }
//
//   /// ==============================
//   /// 形状缓存方法
//   /// ==============================
//
//   /// 获取当前块应该绘制的形状
//   BlockShape getCurrentShape() {
//     final style = blockStyles[blockType] ?? defaultBlockStyle;
//     return style.shape;
//   }
//
//   double _shapeScale(BlockShape shape) {
//     switch (shape) {
//       case BlockShape.circle:
//         return 0.85;
//
//       case BlockShape.square:
//         return 0.83;
//
//       case BlockShape.diamond:
//         return 0.92;
//
//       case BlockShape.triangle:
//         return 1.00;
//
//       case BlockShape.star:
//         return 1.05;
//     }
//   }
//
//   /// 更新缓存的形状（在尺寸或类型改变时调用）
//   void _updateCachedShape() {
//     final shape = getCurrentShape();
//     final center = Offset(size.x / 2, size.y / 2);
//     final shapeSize = size.x * 0.4 * _shapeScale(shape);
//
//     // 如果形状、大小或中心点改变，重新生成缓存
//     if (_cachedShape != shape ||
//         _cachedSize != shapeSize ||
//         _cachedCenter != center) {
//       _cachedShape = shape;
//       _cachedSize = shapeSize;
//       _cachedCenter = center;
//
//       // 根据形状类型生成缓存
//       switch (shape) {
//         case BlockShape.circle:
//           _cachedRadius = shapeSize / 2;
//           _cachedPath = null;
//           break;
//
//         case BlockShape.diamond:
//           _cachedPath = _createRoundedDiamondPath(center, shapeSize);
//           break;
//
//         case BlockShape.square:
//           _cachedPath = _createRoundedSquarePath(center, shapeSize);
//           break;
//
//         case BlockShape.triangle:
//           _cachedPath = _createRoundedTrianglePath(center, shapeSize);
//           break;
//
//         case BlockShape.star:
//           _cachedPath = _createPlumpStarPath(center, shapeSize);
//           break;
//       }
//     }
//   }
//
//   /// 创建带圆角的菱形 Path（简化版）
//   Path _createRoundedDiamondPath(Offset center, double size) {
//     final half = size / 2;
//
//     return _roundedPolygonPath([
//       Offset(center.dx, center.dy - half),
//       Offset(center.dx + half, center.dy),
//       Offset(center.dx, center.dy + half),
//       Offset(center.dx - half, center.dy),
//     ], size * 0.12);
//   }
//
//   /// 创建带圆角的正方形 Path
//   Path _createRoundedSquarePath(Offset center, double size) {
//     final half = size / 2;
//
//     return _roundedPolygonPath([
//       Offset(center.dx - half, center.dy - half),
//       Offset(center.dx + half, center.dy - half),
//       Offset(center.dx + half, center.dy + half),
//       Offset(center.dx - half, center.dy + half),
//     ], size * 0.15);
//   }
//
//   /// 创建带圆角的三角形 Path
//   Path _createRoundedTrianglePath(Offset center, double size) {
//     final half = size / 2;
//     final height = size * 0.866;
//
//     return _roundedPolygonPath([
//       Offset(center.dx, center.dy - height / 2),
//       Offset(center.dx + half, center.dy + height / 2),
//       Offset(center.dx - half, center.dy + height / 2),
//     ], size * 0.12);
//   }
//
//   Path _roundedPolygonPath(List<Offset> points, double radius) {
//     final path = Path();
//
//     for (int i = 0; i < points.length; i++) {
//       final prev = points[(i - 1 + points.length) % points.length];
//       final current = points[i];
//       final next = points[(i + 1) % points.length];
//
//       final v1 = prev - current;
//       final v2 = next - current;
//
//       final d1 = v1.distance;
//       final d2 = v2.distance;
//
//       final r = math.min(radius, math.min(d1, d2) * 0.3);
//
//       final p1 = current + v1 / d1 * r;
//       final p2 = current + v2 / d2 * r;
//
//       if (i == 0) {
//         path.moveTo(p1.dx, p1.dy);
//       } else {
//         path.lineTo(p1.dx, p1.dy);
//       }
//
//       path.quadraticBezierTo(current.dx, current.dy, p2.dx, p2.dy);
//     }
//
//     path.close();
//     return path;
//   }
//
//   /// 创建更饱满的五角星 Path
//   Path _createPlumpStarPath(Offset center, double size) {
//     final outerRadius = size / 2;
//     final innerRadius = outerRadius * 0.55; // 更饱满
//     final points = <Offset>[];
//
//     for (int i = 0; i < 10; i++) {
//       final angle = (i * 36 - 90) * math.pi / 180;
//       final radius = i.isEven ? outerRadius : innerRadius;
//       points.add(
//         Offset(
//           center.dx + radius * math.cos(angle),
//           center.dy + radius * math.sin(angle),
//         ),
//       );
//     }
//
//     return _roundedPolygonPath(points, size * 0.06);
//   }
//
//   /// 绘制中心形状（使用缓存）
//   void _drawCenterShape(Canvas canvas) {
//     final shape = getCurrentShape();
//
//     switch (shape) {
//       case BlockShape.circle:
//         if (_cachedCenter != null && _cachedRadius != null) {
//           canvas.drawCircle(_cachedCenter!, _cachedRadius!, shapePaint);
//         }
//         break;
//
//       case BlockShape.diamond:
//       case BlockShape.square:
//       case BlockShape.triangle:
//       case BlockShape.star:
//         if (_cachedPath != null) {
//           canvas.drawPath(_cachedPath!, shapePaint);
//         }
//         break;
//     }
//   }
//
//   /// ==============================
//   /// 渲染
//   /// ==============================
//
//   @override
//   void render(Canvas canvas) {
//     super.render(canvas);
//
//     if (blockType.isStar) {
//       /// 外边框
//       canvas.drawRRect(rrect, borderPaint);
//
//       if (highlighted) {
//         canvas.drawRRect(rrect, bodyPaint);
//       }
//
//       /// 根据类型绘制中心形状
//       _drawCenterShape(canvas);
//     }
//
//     /// icon
//     // if (icon != null) {
//     //   final iconSize = size.x * 0.8;
//     //   icon!.render(
//     //     canvas,
//     //     position: Vector2((size.x - iconSize) / 2, (size.y - iconSize) / 2),
//     //     size: Vector2.all(iconSize),
//     //   );
//     // }
//   }
// }
