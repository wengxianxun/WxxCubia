// custom_button.dart
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
  final String? text;
  final VoidCallback? onTap;
  final double width;
  final double height;

  // 基础比例参数（相对于按钮短边的比例）
  final double cornerRadiusRatio; // 圆角半径比例，默认 0.15 (短边的15%)
  final double borderThicknessRatio; // 边框厚度比例，默认 0.06 (短边的6%)

  // 颜色配置
  final Color borderColor;
  final Color selectedBorderColor;
  final Color borderInnerGlowColor;
  final Color selectedBorderInnerGlowColor;
  final Color centerStartColor;
  final Color centerEndColor;

  // 描边宽度比例
  final double bevelStrokeWidthRatio; // 内高光描边比例
  final double innerRimStrokeWidthRatio; // 内侧暗边比例
  final double outerEdgeStrokeWidthRatio; // 外边框描边比例
  final double innerEdgeStrokeWidthRatio; // 内边框描边比例
  final double hilightOrgRatio; // 高亮区域偏移比例

  // 文字样式
  final Color textColor;
  final double fontSizeRatio; // 字体大小比例（相对于按钮短边）
  final FontWeight fontWeight;
  final double textScale;

  // 选中状态
  final bool isSelected;

  // 紧凑模式：适用于小按钮，使用更大的比例
  final bool compactMode;

  const CustomButton({
    super.key,
    this.text,
    this.onTap,
    this.width = 200,
    this.height = 60,
    this.cornerRadiusRatio = 0.15, // 增大到15%
    this.borderThicknessRatio = 0.06, // 增大到6%
    this.borderColor = const Color.fromRGBO(247, 156, 49, 1),
    this.selectedBorderColor = const Color.fromRGBO(50, 205, 50, 1),
    this.borderInnerGlowColor = const Color(0xFFFFD54F),
    this.selectedBorderInnerGlowColor = const Color(0xFF90EE90),
    this.centerStartColor = const Color(0xFF00A7FF),
    this.centerEndColor = const Color(0xFF0077FF),
    this.bevelStrokeWidthRatio = 0.02, // 增大到2%
    this.innerRimStrokeWidthRatio = 0.02,
    this.outerEdgeStrokeWidthRatio = 0.02,
    this.innerEdgeStrokeWidthRatio = 0.025,
    this.hilightOrgRatio = 0.03,
    this.textColor = const Color(0xFFFDF7E6),
    this.fontSizeRatio = 0.22, // 增大到22%
    this.fontWeight = FontWeight.bold,
    this.textScale = 1.0,
    this.isSelected = false,
    this.compactMode = false,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isPressed = false;

  // 获取按钮短边长度，用于自适应
  double get _shortSide => min(widget.width, widget.height);

  // 获取实际比例（紧凑模式下使用更大的比例）
  double _getActualRatio(double normalRatio) {
    if (!widget.compactMode) return normalRatio;

    // 紧凑模式下，如果按钮较小，使用动态比例
    if (_shortSide <= 80) {
      return normalRatio * 1.5; // 超小按钮放大1.5倍
    } else if (_shortSide <= 120) {
      return normalRatio * 1.3; // 小按钮放大1.3倍
    }
    return normalRatio * 1.1; // 中等按钮放大1.1倍
  }

  // 根据比例计算实际数值
  double _getActualValue(double ratio) => _shortSide * ratio;

  // 获取实际圆角半径（但不能超过短边的一半）
  double get _actualCornerRadius {
    double maxRadius = _shortSide / 2;
    double ratio = _getActualRatio(widget.cornerRadiusRatio);
    double radius = _getActualValue(ratio);
    return radius.clamp(2.0, maxRadius);
  }

  double get _actualBorderThickness {
    double ratio = _getActualRatio(widget.borderThicknessRatio);
    double value = _getActualValue(ratio);
    return value.clamp(2.0, _shortSide / 3);
  }

  double get _actualBevelStrokeWidth {
    double ratio = _getActualRatio(widget.bevelStrokeWidthRatio);
    return _getActualValue(ratio).clamp(1.0, 6.0);
  }

  double get _actualInnerRimStrokeWidth {
    double ratio = _getActualRatio(widget.innerRimStrokeWidthRatio);
    return _getActualValue(ratio).clamp(0.5, 5.0);
  }

  double get _actualOuterEdgeStrokeWidth {
    double ratio = _getActualRatio(widget.outerEdgeStrokeWidthRatio);
    return _getActualValue(ratio).clamp(0.5, 5.0);
  }

  double get _actualInnerEdgeStrokeWidth {
    double ratio = _getActualRatio(widget.innerEdgeStrokeWidthRatio);
    return _getActualValue(ratio).clamp(0.5, 8.0);
  }

  double get _actualHilightOrg {
    double ratio = _getActualRatio(widget.hilightOrgRatio);
    return _getActualValue(ratio).clamp(2.0, 20.0);
  }

  double get _actualFontSize {
    double ratio = _getActualRatio(widget.fontSizeRatio);
    double fontSize = _getActualValue(ratio);
    return fontSize.clamp(12.0, 100.0); // 最小字体12，确保可读
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Transform.scale(
        scale: _isPressed ? 0.96 : 1.0,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: CustomPaint(
            painter: ButtonPainter(
              width: widget.width,
              height: widget.height,
              cornerRadius: _actualCornerRadius,
              borderThickness: _actualBorderThickness,
              borderColor: widget.isSelected
                  ? widget.selectedBorderColor
                  : widget.borderColor,
              borderInnerGlowColor: widget.isSelected
                  ? widget.selectedBorderInnerGlowColor
                  : widget.borderInnerGlowColor,
              centerStartColor: widget.centerStartColor,
              centerEndColor: widget.centerEndColor,
              bevelStrokeWidth: _actualBevelStrokeWidth,
              innerRimStrokeWidth: _actualInnerRimStrokeWidth,
              outerEdgeStrokeWidth: _actualOuterEdgeStrokeWidth,
              innerEdgeStrokeWidth: _actualInnerEdgeStrokeWidth,
              hilightOrg: _actualHilightOrg,
              text: widget.text,
              textColor: widget.textColor,
              fontSize: _actualFontSize,
              fontWeight: widget.fontWeight,
              textScale: widget.textScale,
            ),
          ),
        ),
      ),
    );
  }
}

class ButtonPainter extends CustomPainter {
  final double width;
  final double height;
  final double cornerRadius;
  final double borderThickness;
  final Color borderColor;
  final Color borderInnerGlowColor;
  final Color centerStartColor;
  final Color centerEndColor;
  final double bevelStrokeWidth;
  final double innerRimStrokeWidth;
  final double outerEdgeStrokeWidth;
  final double innerEdgeStrokeWidth;
  final double hilightOrg;
  final String? text;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final double textScale;

  ButtonPainter({
    required this.width,
    required this.height,
    required this.cornerRadius,
    required this.borderThickness,
    required this.borderColor,
    required this.borderInnerGlowColor,
    required this.centerStartColor,
    required this.centerEndColor,
    required this.bevelStrokeWidth,
    required this.innerRimStrokeWidth,
    required this.outerEdgeStrokeWidth,
    required this.innerEdgeStrokeWidth,
    required this.hilightOrg,
    this.text,
    required this.textColor,
    required this.fontSize,
    required this.fontWeight,
    required this.textScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = width;
    final h = height;
    final r = cornerRadius;

    // 外边框渐变
    final borderPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = ui.Gradient.linear(Offset(0, h), Offset(0, 0), [
        borderColor,
        borderInnerGlowColor,
      ]);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), Radius.circular(r)),
      borderPaint,
    );

    // 外框褐色描边
    final outerEdgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerEdgeStrokeWidth
      ..shader = ui.Gradient.linear(
        Offset(w / 2, 0),
        Offset(w / 2, h),
        [
          const Color(0xFFD67726).withOpacity(1),
          const Color(0xFFD67726).withOpacity(0.8),
          const Color(0xFFD67726).withOpacity(0.6),
          const Color(0xFFD67726).withOpacity(0.5),
        ],
        [0.0, 0.3, 0.7, 1.0],
      );

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), Radius.circular(r)),
      outerEdgePaint,
    );

    final innerInset = borderThickness;
    final innerRect = Rect.fromLTWH(
      innerInset,
      innerInset,
      w - 2 * innerInset,
      h - 2 * innerInset,
    );
    final innerRadius = (r - innerInset).clamp(0.0, double.infinity);

    // 内高光
    final bevelPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = bevelStrokeWidth
      ..shader = ui.Gradient.linear(Offset(0, 0), Offset(0, h), [
        Colors.white.withOpacity(0.28),
        Colors.white.withOpacity(0.08),
      ]);

    canvas.drawRRect(innerRect.deflate(1.5).toRRect(innerRadius), bevelPaint);

    // 中心渐变
    final centerPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = ui.Gradient.linear(
        Offset(0, h - borderThickness),
        Offset(0, borderThickness),
        [centerEndColor, centerStartColor],
      );

    canvas.drawRRect(innerRect.toRRect(innerRadius), centerPaint);

    // 内框褐色描边
    final innerEdgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = innerEdgeStrokeWidth
      ..shader = ui.Gradient.linear(
        Offset(innerRect.center.dx, innerRect.top),
        Offset(innerRect.center.dx, innerRect.bottom),
        [
          const Color(0xFFD67726).withOpacity(1),
          const Color(0xFFD67726).withOpacity(0.8),
          const Color(0xFFD67726).withOpacity(0.5),
        ],
        [0.0, 0.5, 1.0],
      );

    canvas.drawRRect(innerRect.toRRect(innerRadius), innerEdgePaint);

    // 上方高光
    final highlightRect = Rect.fromLTWH(
      innerRect.left + hilightOrg,
      innerRect.top + hilightOrg,
      innerRect.width - hilightOrg * 2,
      innerRect.height - hilightOrg * 2,
    );

    final topHighlightPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = ui.Gradient.linear(
        Offset(0, h - borderThickness),
        Offset(0, borderThickness),
        [Colors.white24, Colors.white10],
      );

    canvas.drawRRect(highlightRect.toRRect(innerRadius), topHighlightPaint);

    // 白色细线描边
    final whiteLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withOpacity(0.6);

    canvas.drawRRect(highlightRect.toRRect(innerRadius), whiteLinePaint);

    // 内侧暗边
    final innerRimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = innerRimStrokeWidth
      ..color = Colors.black.withOpacity(0.25);

    canvas.drawRRect(
      innerRect.deflate(1.5).toRRect(innerRadius - 1.5),
      innerRimPaint,
    );

    // 绘制文字
    if (text != null && text!.isNotEmpty) {
      _drawText(canvas, innerRect);
    }
  }

  void _drawText(Canvas canvas, Rect innerRect) {
    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: 1.0,
      color: textColor,
    );

    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      textScaleFactor: textScale,
    );

    textPainter.layout(minWidth: innerRect.width, maxWidth: innerRect.width);

    final offset = Offset(
      innerRect.left + (innerRect.width - textPainter.width) / 2,
      innerRect.top + (innerRect.height - textPainter.height) / 2,
    );

    // 多层描边实现立体效果（描边宽度也根据字体大小自适应）
    final strokeWidth1 = (fontSize * 0.16).clamp(1.0, 8.0);
    final strokeWidth2 = (fontSize * 0.12).clamp(0.8, 6.0);
    final strokeWidth3 = (fontSize * 0.06).clamp(0.5, 4.0);

    final strokeLayers = [
      {'width': strokeWidth1, 'offset': const Offset(0, 1.2), 'opacity': 0.5},
      {'width': strokeWidth2, 'offset': const Offset(0, 0.6), 'opacity': 0.4},
      {'width': strokeWidth3, 'offset': const Offset(0, 0), 'opacity': 0.3},
    ];

    for (final layer in strokeLayers) {
      final strokePainter = TextPainter(
        text: TextSpan(
          text: text,
          style: textStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = layer['width'] as double
              ..color = const Color(
                0xFF005195,
              ).withOpacity(layer['opacity'] as double),
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        textScaleFactor: textScale,
      );

      strokePainter.layout(
        minWidth: innerRect.width,
        maxWidth: innerRect.width,
      );
      strokePainter.paint(canvas, offset + (layer['offset'] as Offset));
    }

    // 绘制填充文字
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant ButtonPainter oldDelegate) {
    return oldDelegate.width != width ||
        oldDelegate.height != height ||
        oldDelegate.cornerRadius != cornerRadius ||
        oldDelegate.borderThickness != borderThickness ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderInnerGlowColor != borderInnerGlowColor ||
        oldDelegate.centerStartColor != centerStartColor ||
        oldDelegate.centerEndColor != centerEndColor ||
        oldDelegate.text != text ||
        oldDelegate.fontSize != fontSize;
  }
}

extension on Rect {
  RRect toRRect(double radius) => RRect.fromRectAndRadius(
    this,
    Radius.circular(radius.clamp(0.0, double.infinity)),
  );
}
