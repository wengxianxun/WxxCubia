// 添加颜色选择窗口类
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/base_block.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/block_type.dart';
import 'package:wxx_cubia/pages/popstar_game/game/gameplay_scene.dart';
import 'package:wxx_cubia/pages/popstar_game/pop_star_game.dart';

class PenBlockSelectWindow extends PositionComponent
    with HasGameRef<PopStarGame> {
  BaseBlock targetBlock;
  final GameplayScene scene;
  final Function(BlockType) onColorSelected;
  final Function() onClose;

  final double gameWidth;
  final double gameHeight;

  PenBlockSelectWindow({
    required this.targetBlock,
    required this.scene,
    required this.onColorSelected,
    required this.onClose,
    required this.gameWidth,
    required this.gameHeight,
  });

  // 更新目标方块并重新定位窗口
  void updateTargetBlock(BaseBlock newTargetBlock) {
    targetBlock.stopPulseAnimation(); //旧的停止
    targetBlock = newTargetBlock;
    targetBlock.startPulseAnimation(); //开始放大缩小
    // 重新计算窗口位置
    const padding = 10.0;
    const arrowHeight = 10.0;
    const strokeWidth = 5.0;
    Color windowColor = Colors.black87;
    Color borderColor = Colors.tealAccent;

    // 计算窗口尺寸
    final windowWidth = size.x;
    final windowHeight = size.y - arrowHeight;

    // 计算理想位置（基于目标方块上方）
    double windowX = targetBlock.position.x - windowWidth / 2;
    double windowY =
        targetBlock.position.y - windowHeight - 10 - targetBlock.size.y / 2;

    // 边界检查：确保窗口在屏幕内
    // 左右边界
    if (windowX < padding) {
      windowX = padding;
    } else if (windowX + windowWidth > gameWidth - padding) {
      windowX = gameWidth - windowWidth - padding;
    }

    // 上下边界 - 优先显示在上方，如果上方空间不足则显示在下方
    if (windowY < padding) {
      // 上方空间不足，显示在下方
      windowY = targetBlock.position.y + 10;
      // 如果下方也空间不足，显示在尽量上方
      if (windowY + windowHeight > gameHeight - padding) {
        windowY = padding;
      }
    }

    // 更新窗口位置
    position = Vector2(windowX, windowY);

    // 更新箭头位置，使其指向新的目标方块
    final arrowComponents = children.whereType<PolygonComponent>().toList();
    for (var arrow in arrowComponents) {
      arrow.position = Vector2(
        targetBlock.position.x - position.x,
        windowHeight,
      );
    }

    // 移除现有的背景和边框组件
    final backgroundComponents = children
        .whereType<RectangleComponent>()
        .toList();
    for (var component in backgroundComponents) {
      remove(component);
    }

    // 重新添加窗口背景和边框
    windowBackGroundCP(windowWidth, windowHeight);
    borderCp(windowWidth, windowHeight, strokeWidth, windowColor, borderColor);

    // 更新颜色选择按钮，移除与目标方块相同颜色的选项
    final buttonComponents = children.whereType<ButtonComponent>().toList();
    for (var button in buttonComponents) {
      // 跳过关闭按钮
      if (button.position.x > windowWidth - 60) continue;

      remove(button);
    }

    // 重新添加颜色选择按钮
    starBlockCP(40.0, 10.0, 10.0, 10.0);

    // 重新添加关闭按钮
    closeCp(
      50.0, // closeWidth
      windowHeight - strokeWidth, // closeHight
      windowWidth,
      strokeWidth,
      windowHeight,
      windowColor,
    );

    arrowCP(arrowHeight, windowHeight, windowColor, borderColor);
  }

  @override
  void onRemove() {
    // TODO: implement onRemove
    targetBlock.stopPulseAnimation();
    super.onRemove();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    targetBlock.startPulseAnimation(); //开始放大缩小
    // 添加颜色选择按钮
    const buttonSize = 40.0;
    const buttonMargin = 10.0;
    const startX = 10.0;
    const startY = 10.0;
    const arrowHeight = 10.0;
    const closeWidth = 50.0;
    const strokeWidth = 5.0;
    Color windowColor = Colors.black87;
    Color borderColor = Colors.tealAccent;
    // 计算窗口位置，确保在屏幕内显示
    final windowWidth =
        buttonSize * 4 + buttonMargin * 3 + startX * 2 + closeWidth;
    final windowHeight = buttonSize + startY * 2;
    final closeHight = windowHeight - strokeWidth;
    final padding = 10.0; // 边距
    // 获取游戏尺寸
    final gameWidth = gameRef.size.x;
    final gameHeight = gameRef.size.y;
    // 计算理想位置（基于目标方块上方）
    double windowX =
        targetBlock.position.x + targetBlock.size.x / 2 - windowWidth / 2;
    double windowY =
        targetBlock.position.y - windowHeight - 10 - targetBlock.size.y / 2;
    // 边界检查：确保窗口在屏幕内
    // 左右边界
    if (windowX < padding) {
      windowX = padding;
    } else if (windowX + windowWidth > gameWidth - padding) {
      windowX = gameWidth - windowWidth - padding;
    }
    // 上下边界 - 优先显示在上方，如果上方空间不足则显示在下方
    if (windowY < padding) {
      // 上方空间不足，显示在下方
      windowY = targetBlock.position.y + 10;
      // 如果下方也空间不足，显示在尽量上方
      if (windowY + windowHeight > gameHeight - padding) {
        windowY = padding;
      }
    }
    // 使用传入的位置
    position = Vector2(windowX, windowY);
    // 确保位置是有效的
    if (position.x.isNaN || position.y.isNaN) {
      position = Vector2(0, 0);
    }

    //窗口背景
    windowBackGroundCP(windowWidth, windowHeight);
    // 设置组件的整体大小，包括箭头
    size = Vector2(windowWidth, windowHeight + arrowHeight);
    //边框
    borderCp(windowWidth, windowHeight, strokeWidth, windowColor, borderColor);

    //可选星星列表
    starBlockCP(buttonSize, startX, buttonMargin, startY);

    //关闭按钮
    closeCp(
      closeWidth,
      closeHight,
      windowWidth,
      strokeWidth,
      windowHeight,
      windowColor,
    );
    //底部箭头
    arrowCP(arrowHeight, windowHeight, windowColor, borderColor);
  }

  void windowBackGroundCP(double windowWidth, double windowHeight) {
    // 创建窗口背景
    final background = RectangleComponent(
      size: Vector2(windowWidth, windowHeight),
      paint: Paint()
        ..color = Color.fromRGBO(255, 255, 255, 0.85)
        ..style = PaintingStyle.fill,
      anchor: Anchor.topLeft,
    );
    add(background);
  }

  void borderCp(
    double windowWidth,
    double windowHeight,
    double strokeWidth,
    Color windowColor,
    Color borderColor,
  ) {
    // 绘制圆角边框
    final border = RectangleComponent(
      size: Vector2(windowWidth, windowHeight),
      position: Vector2(0, 0),
      paint: Paint()
        ..color = windowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
      anchor: Anchor.topLeft,
    );
    add(border);

    final border2 = RectangleComponent(
      size: Vector2(windowWidth + 4, windowHeight + 4),
      position: Vector2(-2, -2),
      paint: Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
      anchor: Anchor.topLeft,
    );
    add(border2);
  }

  Future<void> closeCp(
    double closeWidth,
    double closeHight,
    double windowWidth,
    double strokeWidth,
    double windowHeight,
    Color windowColor,
  ) async {
    // 添加关闭按钮 - 使用RectangleComponent而不是SpriteComponent来避免sprite错误
    final rightBackground = ButtonComponent(
      button: RectangleComponent(
        size: Vector2(closeWidth, closeHight), // 正方形尺寸（24x24，可以根据需要调整）
        paint: Paint()..color = windowColor,
      ),
      onPressed: () {
        onClose();
        removeFromParent();
      },
      position: Vector2(
        windowWidth - closeWidth - strokeWidth / 2,
        strokeWidth / 2,
      ),
      anchor: Anchor.topLeft,
    );

    add(rightBackground);

    // 添加关闭按钮图片
    final closeSprite = await gameRef.loadSprite('btn/close.png');

    final closeIcon = SpriteComponent(
      sprite: closeSprite,
      size: Vector2(22, 22), // 图片大小相对按钮稍小
      position: Vector2(windowWidth - closeWidth / 2, windowHeight / 2),
      anchor: Anchor.center,
    );
    add(closeIcon);
  }

  void starBlockCP(
    double buttonSize,
    double startX,
    double buttonMargin,
    double startY,
  ) {
    // 获取除当前颜色外的其他四种颜色
    final currentType = targetBlock.blockType;
    final availableColors = [
      BlockType.red_star,
      BlockType.blue_star,
      BlockType.green_star,
      BlockType.yellow_star,
      BlockType.purple_star,
    ].where((type) => type != currentType).toList();

    for (int i = 0; i < availableColors.length; i++) {
      final colorType = availableColors[i];

      // 创建按钮组件，确保有有效的显示内容
      Component buttonContent;

      // 检查精灵是否存在，如果存在则使用精灵，否则使用颜色块
      final sprite = scene.sprites[colorType.value];
      if (sprite != null) {
        buttonContent = SpriteComponent(
          sprite: sprite,
          size: Vector2.all(buttonSize),
        );
      } else {
        // 作为后备方案，使用纯色方块
        buttonContent = RectangleComponent(
          size: Vector2.all(buttonSize),
          paint: Paint()..color = _getColorForBlockType(colorType),
        );
      }

      final button = ButtonComponent(
        button: buttonContent as PositionComponent,
        onPressed: () {
          onColorSelected(colorType);
          removeFromParent();
        },
        position: Vector2(startX + i * (buttonSize + buttonMargin), startY),
        anchor: Anchor.topLeft,
      );
      add(button);
    }
  }

  void arrowCP(
    double arrowHeight,
    double windowHeight,
    Color windowColor,
    Color borderColor,
  ) {
    final arrow2 = PolygonComponent(
      [
        Vector2(0, arrowHeight), // 底边中点（下）
        Vector2(-10, 0), // 左上角
        Vector2(10, 0), // 右上角
      ],
      paint: Paint()..color = borderColor,
      position: Vector2(targetBlock.position.x - position.x, windowHeight + 2),
      anchor: Anchor.topCenter,
    )..angle = 0; // 指向下方，可改角度旋转
    add(arrow2);
    // 添加底部三角箭头指向目标方块
    final arrow = PolygonComponent(
      [
        Vector2(0, arrowHeight), // 底边中点（下）
        Vector2(-10, 0), // 左上角
        Vector2(10, 0), // 右上角
      ],
      paint: Paint()..color = windowColor,
      position: Vector2(targetBlock.position.x - position.x, windowHeight),
      anchor: Anchor.topCenter,
    )..angle = 0; // 指向下方，可改角度旋转
    add(arrow);
  }

  // 根据方块类型获取对应的颜色
  Color _getColorForBlockType(BlockType type) {
    switch (type) {
      case BlockType.red_star:
        return Colors.red;
      case BlockType.blue_star:
        return Colors.blue;
      case BlockType.green_star:
        return Colors.green;
      case BlockType.yellow_star:
        return Colors.yellow;
      case BlockType.purple_star:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
