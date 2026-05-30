// lib/components/generated_button.dart
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:wxx_cubia/util_flame/btn/g_base_button.dart';

class GTextButton extends GBaseButton {
  // 新增文字参数
  final String text;
  final TextStyle textStyle;
  final double textScale;

  GTextButton({
    super.position,
    super.size,
    super.anchor = Anchor.center,
    super.onTap,
    super.pressedScale = 0.96,
    super.cornerRadius = 20.0,
    super.borderThickness = 8.0,
    super.borderColor = const Color.fromRGBO(247, 156, 49, 1),
    super.borderInnerGlowColor = const Color(0xFFFFD54F),
    super.centerStartColor = const Color(0xFF00A7FF),
    super.centerEndColor = const Color(0xFF0077FF),
    super.shadowBlur = 13.0,

    // 新增文字参数
    this.text = '',
    TextStyle? textStyle,
    this.textScale = 1.0,
  }) : textStyle =
           textStyle ??
           const TextStyle(
             fontSize: 25,
             fontWeight: FontWeight.bold,
             height: 1.0,
             color: const Color(0xFFFDF7E6),
           );

  @override
  void render(Canvas canvas) {
    // 先调用父类的渲染方法绘制基础按钮
    super.render(canvas);

    // 然后绘制文字
    if (text.isNotEmpty) {
      final innerInset = borderThickness;
      final innerRect = Rect.fromLTWH(
        innerInset,
        innerInset,
        size.x - 2 * innerInset,
        size.y - 2 * innerInset,
      );
      final innerRadius = max(0, cornerRadius - innerInset);

      _drawText(canvas, innerRect, innerRadius.toDouble());
    }
  }

  void _drawText(Canvas canvas, Rect innerRect, double innerRadius) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      textScaleFactor: textScale,
    );

    textPainter.layout(minWidth: innerRect.width, maxWidth: innerRect.width);

    final offset = Offset(
      innerRect.left + (innerRect.width - textPainter.width) / 2,
      innerRect.top + (innerRect.height - textPainter.height) / 2,
    );

    // 多层描边实现上细下粗的立体效果
    final strokeLayers = [
      {'width': 4.0, 'offset': const Offset(0, 1), 'opacity': 0.5}, // 最底层粗描边
      {'width': 3.0, 'offset': const Offset(0, 0.5), 'opacity': 0.4}, // 中间层
      {'width': 1.5, 'offset': const Offset(0, 0), 'opacity': 0.3}, // 顶层细描边
    ];

    // 从底层到顶层绘制描边
    for (final layer in strokeLayers) {
      final strokePainter = TextPainter(
        text: TextSpan(
          text: text,
          style: textStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = layer['width'] as double
              ..color = Color(
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

    // 最后绘制填充文字
    textPainter.paint(canvas, offset);
  }
}
