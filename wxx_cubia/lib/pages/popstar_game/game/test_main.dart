import 'dart:math';

import 'package:flutter/material.dart';

void main() => runApp(const PopStarStars());

class PopStarStars extends StatelessWidget {
  const PopStarStars({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Popstar 星星示例")),
        backgroundColor: Colors.black,
        body: const Center(child: StarRow()),
      ),
    );
  }
}

class StarRow extends StatelessWidget {
  const StarRow({super.key});

  final List<Color> starColors = const [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.purple,
    Colors.yellow,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: starColors.map((color) {
        // return Container(
        //   margin: EdgeInsets.all(1),
        //   decoration: BoxDecoration(
        //     color: color,
        //     borderRadius: BorderRadius.all(Radius.circular(6)),
        //   ),
        //   child: Padding(
        //     padding: const EdgeInsets.all(12.0),
        //     child: CustomPaint(
        //       painter: StarPainter(color),
        //       size: const Size(50, 50),
        //     ),
        //   ),
        // );
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: CustomPaint(
                  painter: StarPainter(color), // 替换成传入 color
                  size: Size(50, 50),
                ),
              ),
            ),
            // 👇 覆盖半透明弧形
            Positioned.fill(child: CustomPaint(painter: ArcFanMaskPainter())),
          ],
        );
      }).toList(),
    );
  }
}

class ArcFanMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black
          .withOpacity(0.1) // 黑色半透明
      ..style = PaintingStyle.fill;

    final Path path = Path();

    final Offset leftBottom = Offset(18, size.height);
    final Offset rightTop = Offset(size.width, 15);
    final Offset rightBottom = Offset(size.width, size.height);

    // 起点：左下
    path.moveTo(leftBottom.dx, leftBottom.dy);

    // 弧线连接到右上角
    path.arcToPoint(
      rightTop,
      radius: Radius.elliptical(size.width, size.height),
      largeArc: false,
      clockwise: true,
    );

    // 到右下角
    path.lineTo(rightBottom.dx, rightBottom.dy);

    // 回到起点形成闭合
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StarPainter extends CustomPainter {
  final Color color;
  final double cornerRadius;

  StarPainter(this.color, {this.cornerRadius = 4.0});

  @override
  void paint(Canvas canvas, Size size) {
    final double outerRadius = size.width / 2;
    final double innerRadius = outerRadius * 0.5;
    final Offset center = Offset(size.width / 2, size.height / 2);
    const int numPoints = 5;

    final path = Path();
    final List<Offset> points = [];

    for (int i = 0; i < numPoints * 2; i++) {
      double angle = pi / numPoints * i - pi / 2;
      double r = i % 2 == 0 ? outerRadius : innerRadius;
      double x = center.dx + r * cos(angle);
      double y = center.dy + r * sin(angle);
      points.add(Offset(x, y));
    }

    // 带圆角路径
    for (int i = 0; i < points.length; i++) {
      Offset p0 = points[(i - 1 + points.length) % points.length];
      Offset p1 = points[i];
      Offset p2 = points[(i + 1) % points.length];

      final v1 = (p0 - p1).direction;
      final v2 = (p2 - p1).direction;

      final offset1 = Offset(cos(v1) * cornerRadius, sin(v1) * cornerRadius);
      final offset2 = Offset(cos(v2) * cornerRadius, sin(v2) * cornerRadius);

      if (i == 0) {
        path.moveTo(p1.dx + offset1.dx, p1.dy + offset1.dy);
      } else {
        path.lineTo(p1.dx + offset1.dx, p1.dy + offset1.dy);
      }

      path.quadraticBezierTo(
        p1.dx,
        p1.dy,
        p1.dx + offset2.dx,
        p1.dy + offset2.dy,
      );
    }
    path.close();
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6); // 软阴影

    canvas.save();
    canvas.translate(2, 3); // 位移产生“阴影感”
    canvas.drawPath(path, shadowPaint);
    canvas.restore();
    canvas.drawShadow(
      path,
      Colors.black.withOpacity(0.6), // 更深更明显
      10.0, // 增加偏移高度
      true,
    );

    // ⭐ 填充
    final gradientPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3), // 光源偏左上角
        radius: 0.8,
        colors: [
          Colors.white.withOpacity(0.7), // 中心亮
          color.withOpacity(1.0), // 主体色
          Colors.black.withOpacity(0.2), // 边缘暗
        ],
        stops: const [0.0, 0.3, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius))
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, gradientPaint);

    // ⭐ 边框
    final strokePaint = Paint()
      ..color = Color.fromRGBO(210, 210, 210, 1)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);

    // ✨ 添加光点高亮（右上角位置）
    final highlightPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.0),
            ],
            radius: 0.5,
          ).createShader(
            Rect.fromCircle(
              center: Offset(center.dx - 8, center.dy - 10),
              radius: 10,
            ),
          );
    canvas.drawCircle(
      Offset(center.dx - 8, center.dy - 10),
      10,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
