import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:wxx_cubia/util/huuua_config.dart';

class AnimatedCandyComponent extends PositionComponent with HasGameRef {
  late final SpriteComponent background;
  late List<AnimatedStar> stars;
  late final TextComponent titleText;
  late final List<String> starImagePaths = [
    'blue.png',
    'purple.png',
    'green.png',
    'red.png',
    'yellow.png',
  ];

  AnimatedCandyComponent({
    Vector2? position,
    Vector2? size,
    Anchor? anchor = Anchor.center,
  }) : super(position: position, size: size, anchor: anchor);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final imgPath = HuuuaConfig.instance.getImagePath();
    // 设置默认大小
    if (size == null) {
      size = Vector2(300, 300);
    }

    // 加载popstar图片作为logo
    final popStarLogoImage = await gameRef.images.load(
      '${imgPath}/poplogo.png',
    );
    final popStarLogo = SpriteComponent(
      sprite: Sprite(popStarLogoImage),
      size: Vector2(300, 190),
      position: Vector2(size!.x / 2, size!.y * 0.8),
      anchor: Anchor.center,
    );
    add(popStarLogo);

    // 创建星星组件
    stars = [];

    // 创建星星的顺序从两边到中间
    int mid = starImagePaths.length ~/ 2;

    // 首先交替创建左右两侧的星星（从最外层开始）
    // for (int i = mid; i >= 1; i--) {
    //   // 计算大小因子：离中间越远，大小越小
    //   double sizeFactor = 1.0 - (i * 0.1); // 最大减少到60%的大小
    //   sizeFactor = sizeFactor.clamp(0.7, 1.0); // 确保大小不小于60%
    //
    //   // 创建左侧的星星
    //   if (mid - i >= 0) {
    //     final leftStar = AnimatedStar(
    //       imagePath: '${imgPath}/${starImagePaths[mid - i]}',
    //       index: mid - i,
    //       logoSize: size!,
    //       sizeFactor: sizeFactor,
    //     );
    //     stars.add(leftStar);
    //     add(leftStar);
    //   }
    //
    //   // 创建右侧的星星
    //   if (mid + i < starImagePaths.length) {
    //     final rightStar = AnimatedStar(
    //       imagePath: '${imgPath}/${starImagePaths[mid + i]}',
    //       index: mid + i,
    //       logoSize: size!,
    //       sizeFactor: sizeFactor,
    //     );
    //     stars.add(rightStar);
    //     add(rightStar);
    //   }
    // }

    // 最后创建中间的星星，确保它在最上方，并且是最大的
    // final centerStar = AnimatedStar(
    //   imagePath: '${imgPath}/${starImagePaths[mid]}',
    //   index: mid,
    //   logoSize: size!,
    //   sizeFactor: 1.0, // 中间星星保持原始大小
    // );
    // stars.add(centerStar);
    // add(centerStar);
  }
}

class AnimatedStar extends SpriteComponent with HasGameRef {
  final String imagePath;
  final int index;
  final Vector2 logoSize;
  final double sizeFactor;
  late final double baseScale;
  late final double animationOffset;
  late final double amplitude;
  late final double frequency;
  late final double rotationSpeed;

  AnimatedStar({
    required this.imagePath,
    required this.index,
    required this.logoSize,
    this.sizeFactor = 1.0,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 加载星星图片
    final image = await gameRef.images.load(imagePath);
    sprite = Sprite(image);

    // 根据星星索引设置不同的动画参数
    baseScale = (0.6 + (index * 0.05)) * sizeFactor; // 基础缩放比例，使用sizeFactor调整
    amplitude = 0.1 + (index * 0.03); // 动画振幅
    frequency = 0.5 + (index * 0.1); // 动画频率
    rotationSpeed = 0.3; // 旋转速度
    animationOffset = index * 0.5; // 动画偏移，使星星动画不同步

    // 计算星星位置 - 上方弧形排列
    double radius = logoSize.x * 0.35; // 星星分布的半径
    // 将五颗星星分布在上半圆，形成弧形效果
    double angle = math.pi + (index / 4) * math.pi; // 从π到2π，覆盖上半圆

    // 设置星星大小和位置，使用sizeFactor调整
    size = Vector2(
      logoSize.x * 0.5 * sizeFactor,
      logoSize.y * 0.5 * sizeFactor,
    );
    position = Vector2(
      logoSize.x / 2 + math.cos(angle) * radius,
      logoSize.y / 2 + math.sin(angle) * radius, // 调整垂直位置，使其在上半部分
    );
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 计算动画时间，加上偏移使星星动画不同步
    double animationTime = gameRef.currentTime() + animationOffset;

    // 缩放动画 - 呼吸效果
    double scale = baseScale + math.sin(animationTime * frequency) * amplitude;
    this.scale = Vector2.all(scale);

    // 旋转动画
    angle += rotationSpeed * dt;

    // 轻微的上下浮动效果
    double floatOffset =
        math.sin(animationTime * frequency * 1.5) * logoSize.y * 0.02;
    // 保持在上半圆弧形位置的基础上添加浮动效果
    double baseAngle = math.pi + (index / 4) * math.pi;
    position.y =
        logoSize.y * 0.6 + math.sin(baseAngle) * logoSize.x * 0.3 + floatOffset;
  }
}
