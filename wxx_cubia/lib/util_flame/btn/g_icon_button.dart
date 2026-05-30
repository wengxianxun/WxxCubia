// lib/util/btn/g_icon_button.dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:wxx_cubia/util_flame/btn/g_base_button.dart';

class GIconButton extends GBaseButton {
  // 图标相关属性
  IconData icon;
  Color iconColor;
  double iconSize;

  GIconButton({
    super.position,
    super.size,
    super.anchor = Anchor.center,
    super.onTap,
    super.pressedScale = 0.96,
    super.cornerRadius = 10.0,

    super.borderThickness = 4.0,
    super.borderColor = const Color.fromRGBO(247, 156, 49, 1),
    super.borderInnerGlowColor = const Color(0xFFFFD54F),
    super.centerStartColor = const Color(0xFF00A7FF),
    super.centerEndColor = const Color(0xFF0077FF),
    super.shadowBlur = 6.0,

    super.bevelStrokeWidth = 1, // 内高光
    super.innerRimStrokeWidth = 1, // 内侧暗边
    super.outerEdgeStrokeWidth = 1.0, //外阴影
    super.innerEdgeStrokeWidth = 1, //内阴影
    super.hilightOrg = 2, //高亮边距
    // 图标参数
    required this.icon,
    this.iconColor = Colors.white,
    this.iconSize = 24.0,
  });

  @override
  void render(Canvas canvas) {
    // 先调用父类的渲染方法绘制基础按钮
    super.render(canvas);

    // 绘制图标
    if (size.x > 0 && size.y > 0) {
      _renderIcon(canvas);
    }
  }

  // 绘制图标
  void _renderIcon(Canvas canvas) {
    final iconPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final iconSpan = TextSpan(
      style: TextStyle(
        color: iconColor,
        fontSize: iconSize,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
      ),
      text: String.fromCharCode(icon.codePoint),
    );

    iconPainter.text = iconSpan;
    iconPainter.layout();

    // 计算图标居中位置
    final positionX = (size.x - iconPainter.width) / 2;
    final positionY = (size.y - iconPainter.height) / 2;

    canvas.save();
    canvas.translate(positionX, positionY);
    iconPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  /// 更新图标
  /// [newIcon] - 新的IconData对象
  /// [color] - 图标颜色（可选）
  /// [size] - 图标大小（可选）
  void updateIcon(IconData newIcon, {Color? color, double? size}) {
    icon = newIcon;
    if (color != null) iconColor = color;
    if (size != null) iconSize = size;
  }

  /// 更新图标颜色
  void updateIconColor(Color newColor) {
    iconColor = newColor;
  }

  /// 更新图标大小
  void updateIconSize(double newSize) {
    iconSize = newSize;
  }
}
