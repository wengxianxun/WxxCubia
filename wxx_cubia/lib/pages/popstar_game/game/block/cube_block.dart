import 'dart:math';

import 'package:flutter/material.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/base_block.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/block_type.dart';

/// 全局随机实例，保证多个星星闪烁颜色不同步
final Random _globalRandom = Random();

/// 扩展方法：根据方块类型返回粒子颜色
extension CubeBlockColor on CubeBlock {
  Color colorForParticle() {
    switch (blockType) {
      case BlockType.red_star:
        return Colors.redAccent;
      case BlockType.blue_star:
        return Colors.blueAccent;
      case BlockType.green_star:
        return Colors.greenAccent;
      case BlockType.yellow_star:
        return Colors.amberAccent;
      case BlockType.purple_star:
        return Colors.purpleAccent;
      default:
        return Colors.white;
    }
  }
}

/// CubeBlock 类
class CubeBlock extends BaseBlock {
  // --- 闪烁动画相关 ---
  bool _isColorChanging = false;
  double _colorChangeProgress = 0;
  double _colorFlashSpeed = 15.0; // 闪烁速度
  int _flashesCount = 0;
  final int _maxFlashes = 8; // 闪烁次数
  BlockType? _targetBlockType;
  List<BlockType> _allStarTypes = [
    BlockType.red_star,
    BlockType.blue_star,
    BlockType.green_star,
    BlockType.yellow_star,
    BlockType.purple_star,
  ];

  CubeBlock({
    required super.row,
    required super.col,
    required super.blockType,
    required super.size,
    super.scene,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();
  }

  /// 切换到指定颜色类型，带随机闪烁动画
  void switchColorTypeWithAnimation(BlockType targetType) {
    if (!_allStarTypes.contains(targetType)) return;

    // 已经在切换或已是目标类型
    if (_isColorChanging) return;

    _isColorChanging = true;
    _colorChangeProgress = 0;
    _flashesCount = 0;
    _targetBlockType = targetType;
    startPulseAnimation(); // 缩放动画增强效果
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isColorChanging && _targetBlockType != null) {
      _colorChangeProgress += dt * _colorFlashSpeed;

      if (_colorChangeProgress >= 3.0) {
        _colorChangeProgress = 0;
        _flashesCount++;

        if (_flashesCount < _maxFlashes) {
          // 随机选择一个不同于当前和目标颜色的类型
          List<BlockType> availableTypes = _allStarTypes
              .where((type) => type != blockType && type != _targetBlockType)
              .toList();

          if (availableTypes.isNotEmpty) {
            BlockType flashType =
                availableTypes[_globalRandom.nextInt(availableTypes.length)];
            blockType = flashType;
            _updateSpriteForCurrentType();
          }
        } else {
          // 闪烁完成，切换到目标颜色
          blockType = _targetBlockType!;
          _isColorChanging = false;
          _targetBlockType = null;
          stopPulseAnimation();
          _updateSpriteForCurrentType();
        }
      }
    }
  }

  /// 安全更新精灵
  void _updateSpriteForCurrentType() {
    if (scene != null && scene!.sprites != null) {
      final spriteKey = blockType.value;
      if (scene!.sprites!.containsKey(spriteKey)) {
        // sprite = scene!.sprites![spriteKey];
        updateTypeAndIcon(
          newType: blockType,
          newIcon: scene!.sprites![spriteKey],
        );
      } else {
        print('Warning: Sprite not found for type: $spriteKey');
      }
    } else {
      print(
        'Warning: Cannot update sprite - scene or sprites collection is null',
      );
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
  }

  // 占位：缩放动画方法，可自行实现
  void startPulseAnimation() {}
  void stopPulseAnimation() {}
}
