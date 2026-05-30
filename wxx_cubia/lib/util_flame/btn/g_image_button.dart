// lib/components/generated_button.dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:wxx_cubia/util_flame/btn/g_base_button.dart';

class GImageButton extends GBaseButton {
  // 新增图片参数
  final String image;
  Sprite? _sprite;
  bool _isLoading = false;

  GImageButton({
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
    // 新增图片参数
    this.image = '',
  }) {
    if (image.isNotEmpty) {
      _loadImage();
    }
  }

  // 加载图片
  Future<void> _loadImage() async {
    // setBadgeText("12");
    if (_isLoading || image.isEmpty) return;
    _isLoading = true;
    try {
      final sprite = await Sprite.load(image);
      _sprite = sprite;
    } catch (e) {
      print('Failed to load image: $image, error: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// 更新按钮的精灵图片
  /// [imagePath] - 新的图片路径
  Future<void> updateSprite(String imagePath) async {
    if (_isLoading || imagePath.isEmpty) return;
    _isLoading = true;
    try {
      final sprite = await Sprite.load(imagePath);
      _sprite = sprite;
    } catch (e) {
      print('Failed to update sprite with image: $imagePath, error: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// 直接设置精灵对象
  /// [sprite] - 新的Sprite对象
  void setSprite(Sprite sprite) {
    _sprite = sprite;
  }

  @override
  void render(Canvas canvas) {
    // 先调用父类的渲染方法绘制基础按钮
    super.render(canvas);

    // 绘制图片
    if (_sprite != null && size.x > 0 && size.y > 0) {
      // 计算图片绘制区域，保持图片居中且适应按钮大小
      final imageSize = size * 0.8; // 图片大小为按钮的90%

      // 计算居中位置偏移量
      // 当图片缩放时，我们需要调整position以确保图片居中
      // 正确的居中位置应该是：(size - imageSize) / 2
      final offset = (size - imageSize) / 2;

      // 使用Vector2.zero()并配合锚点实现居中可能会导致缩放后不居中
      // 改为直接绘制在正确的位置上
      _sprite?.render(canvas, position: offset, size: imageSize);
    }
  }
}
