import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wxx_cubia/component/hammer_button.dart';
import 'package:wxx_cubia/component/huuua_btn_component.dart';
import 'package:wxx_cubia/component/pen_button.dart';
import 'package:wxx_cubia/component/refresh_button.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/base_block.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/block_type.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/box_block.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/box_open_animation.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/lightning_block.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/radar_block.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/rainbow_block.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/rocket_block.dart';
import 'package:wxx_cubia/pages/popstar_game/game/block/star_block.dart';
import 'package:wxx_cubia/pages/popstar_game/game/component/combo_component.dart';
import 'package:wxx_cubia/pages/popstar_game/game/component/floating_score_component.dart';
import 'package:wxx_cubia/pages/popstar_game/game/component/game_over_component.dart';
import 'package:wxx_cubia/pages/popstar_game/game/component/laser_beam_component.dart';
import 'package:wxx_cubia/pages/popstar_game/game/component/lightning_component.dart';
import 'package:wxx_cubia/pages/popstar_game/game/component/pen_block_select_window.dart';
import 'package:wxx_cubia/pages/popstar_game/game/component/praise_effect_component.dart';
import 'package:wxx_cubia/pages/popstar_game/game/component/rocket_arc_with_trail.dart';
import 'package:wxx_cubia/pages/popstar_game/game/component/star_explosion_component.dart';
import 'package:wxx_cubia/pages/popstar_game/game/manager/combo_manager.dart';
import 'package:wxx_cubia/pages/popstar_game/game/manager/game_data_manager.dart';
import 'package:wxx_cubia/pages/popstar_game/pop_star_game.dart';
import 'package:wxx_cubia/util/dialog/gameover_dialog/gameover_dialog.dart';
import 'package:wxx_cubia/util/dialog/revive_dialog/revive_dialog.dart';
import 'package:wxx_cubia/util/dialog/revive_success_dialog/revive_success_dialog.dart';
import 'package:wxx_cubia/util/huuua_config.dart';
import 'package:wxx_cubia/util/huuua_dialog.dart';
import 'package:wxx_cubia/util_flame/audio_controller.dart';
import 'package:wxx_cubia/util_flame/btn/g_icon_button.dart';
import 'package:wxx_cubia/util_flame/btn/g_text_button.dart';
import 'package:wxx_cubia/util_flame/setting_button.dart';
import 'package:wxx_cubia/util_flame/sound_pool.dart';

// MediaQuery.of(context).viewPadding.bottom
// 在文件顶部添加游戏数据管理器的引用
final gameDataManager = GameDataManager();

class GameplayScene extends PositionComponent
    with HasGameRef<PopStarGame>, WidgetsBindingObserver {
  final VoidCallback onExitPressed;
  final bool startNewGame;
  bool hasMadeElimination = false; // 添加这个标志变量
  int refreshCount = 3; // 默认3次刷新机会
  TextComponent? refreshCountText; // 用于显示刷新次数的文本组件
  // 概率盲盒
  final Random _rnd = Random();
  // 跟踪当前显示的颜色选择窗口
  PenBlockSelectWindow? _currentColorWindow;

  // combo连击
  late final ComboManager comboManager;
  ComboTextComponent? _comboTextComponent;
  //

  // 提示文字组件
  TextComponent? _colorSelectionHintText;
  // 锤子功能相关
  BaseBlock? _hammerSelectedBlock;

  TextComponent? _hammerHintText;

  SpriteComponent? _hammerAnimationComponent;

  LightningBlock? lightningBlock; //游戏中生成的闪电，一局游戏只能存在一个闪电
  RadarBlock? radarBlock; //游戏中生成的雷达，一局游戏只能存在一个雷达

  GameplayScene({required this.onExitPressed, this.startNewGame = false});

  static const int rows = 10;
  static const int cols = 10;

  late double blockSize;
  static const double padding = 1.0;

  final List<List<BaseBlock?>> grid = []; //baseblock， 可以实例多种子类
  final Random random = Random();
  // 将字符串类型的starTypes替换为BlockType枚举列表
  final List<BlockType> blockTypes = [
    BlockType.red_star,
    BlockType.blue_star,
    BlockType.green_star,
    BlockType.yellow_star,
    BlockType.purple_star,
  ];

  late Map<String, Sprite> sprites;
  Set<String> currentlyHighlighted = {};
  // 添加这个变量来标记是否正在处理消除动画
  bool isProcessingElimination = false;
  bool _isDropAnimating = false; // 添加这一行
  late final safeAreaTop = MediaQuery.of(gameRef.buildContext!).viewPadding.top;
  late final safeAreaBottom = MediaQuery.of(
    gameRef.buildContext!,
  ).viewPadding.bottom;
  late double offsetY;

  late TextComponent targetLabel;
  late TextComponent targetText;
  late TextComponent scoreLabel;
  late TextComponent scoreText;
  late TextComponent levelLabel;
  late TextComponent levelText;

  late GameOverComponent gameOverComponents;
  late GTextButton newGameButton;

  late HammerButton hammerBtn;
  late PenButton penBtn;
  late RefreshButton refreshButton;

  bool hasShownLevelCompleteMessage = false; // 防止重复显示通关提示
  bool isGameOverUIActive = false; // 标志游戏结束界面是否激活

  // 修改onRemove方法，添加保存游戏状态的逻辑
  @override
  void onRemove() {
    // 移除生命周期监听器
    WidgetsBinding.instance.removeObserver(this);

    // 停止背景音乐
    SoundPool().stopBackground();

    // 保存游戏状态
    saveGameState();

    // 清理文本组件资源
    remove(targetLabel);
    remove(targetText);
    remove(scoreLabel);
    remove(scoreText);
    remove(levelLabel);
    remove(levelText);

    // 清理combo文本组件
    if (_comboTextComponent != null) {
      remove(_comboTextComponent!);
      _comboTextComponent = null;
    }

    // GameDataManager().dispose();

    super.onRemove();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = gameRef.size;

    // 如果是开始新游戏，清除保存的状态
    if (startNewGame) {
      await gameDataManager.clearGameState();
      refreshCount = 3; // 新游戏重置刷新次数
    } else {
      // 先检查是否需要从保存的状态恢复游戏
      final savedState = await gameDataManager.loadGameState();
      if (savedState != null) {
        // 先恢复游戏数据管理器的状态
        final level = savedState['level'] as int;
        final score = savedState['score'] as int;
        // 尝试从保存的状态中恢复刷新次数
        final savedRefreshCount = savedState['refreshCount'] as int? ?? 3;
        refreshCount = savedRefreshCount;
        gameDataManager.setLevel(level);
        gameDataManager.setScore(score);
      }
    }

    // 再初始化游戏数据和UI（这样UI会使用最新的分数）
    await _initializeDataAndUI();

    // 初始化或恢复网格
    if (startNewGame) {
      _initializeGrid();
    } else {
      final savedState = await gameDataManager.loadGameState();
      if (savedState != null) {
        final gridData = savedState['grid'] as List<List<int?>>;
        _initializeGridFromSavedData(gridData);
      } else {
        _initializeGrid();
      }
    }

    comboManager = ComboManager(
      comboBreakTime: 5, //combo倒计时
      minClearForCombo: 2, //最少消除数量
      onCombo: _onCombo,
      onComboBreak: _onComboBreak,
    );

    //
    // add(
    //   RainbowArcComponent(
    //     size: Vector2(280, 280), // 调整大小为更合适的尺寸
    //     position: Vector2(80, 160), // 放在右上角，确保在屏幕内
    //   )..priority = 999, // 设置最高优先级确保显示在最上层
    // );

    // RadarBlock.createAndInitialize(
    //   1,
    //   1,
    //   this,
    //   blockSize,
    //   padding,
    //   offsetY,
    //   BlockType.lightning,
    // );

    // final block = StarBlock(
    //   row: 1,
    //   col: 1,
    //   blockType: BlockType.red_star,
    //   sprite: sprites[BlockType.red_star]!,
    //   size: Vector2(100, 100),
    //   scene: this,
    // );
    //
    // block.position = Vector2(300, 300);
    //
    // add(block);

    // final bgSprite = sprites[BlockType.moon_background.value];
    // final block = RadarBlock(
    //   row: 1,
    //   col: 1,
    //   sprite: bgSprite!,
    //   size: Vector2.all(200),
    //   scene: this,
    //
    //   blockType: BlockType.lightning,
    // );
    //
    // block.position = Vector2(200, 400);
    //
    // add(block);

    // final starblock = StarBlock(
    //   row: 1,
    //   col: 1,
    //   blockType: BlockType.red_star,
    //   iconSprite: await Sprite.load('star/red.png'),
    //   size: Vector2(90, 90),
    //   // scene: this,
    // );
    //
    // starblock.position = Vector2(100, 200);
    // add(starblock);
  }

  @override
  Future<void> onMount() async {
    super.onMount();
    WidgetsBinding.instance.addObserver(this);
    //

    // 使用FlameAudio的BGM系统播放背景音乐
    if (!AudioController.isMuted && !HuuuaConfig.isDebug) {
      SoundPool().playBackground();
    }

    // changeToGameOver();
  }

  // 添加方法来初始化数据和UI
  Future<void> _initializeDataAndUI() async {
    // 初始化 block 尺寸和偏移
    blockSize = (size.x - (cols - 1) * padding) / cols;
    offsetY = size.y - (rows * (blockSize + padding)) - safeAreaBottom;

    final imgPath = HuuuaConfig.instance.getImagePath();

    // 加载方块图像
    sprites = {
      BlockType.box.value: await gameRef.loadSprite("box.png"),
      BlockType.red_star.value: await gameRef.loadSprite('${imgPath}/red.png'),
      BlockType.blue_star.value: await gameRef.loadSprite(
        '${imgPath}/blue.png',
      ),
      BlockType.green_star.value: await gameRef.loadSprite(
        '${imgPath}/green.png',
      ),
      BlockType.yellow_star.value: await gameRef.loadSprite(
        '${imgPath}/yellow.png',
      ),
      BlockType.purple_star.value: await gameRef.loadSprite(
        '${imgPath}/purple.png',
      ),
      BlockType.rocket_blue.value: await gameRef.loadSprite('rocket_blue.png'),
      BlockType.rocket_green.value: await gameRef.loadSprite(
        'rocket_green.png',
      ),
      BlockType.rocket_purple.value: await gameRef.loadSprite(
        'rocket_purple.png',
      ),
      BlockType.rocket_red.value: await gameRef.loadSprite('rocket_red.png'),
      BlockType.rocket_yellow.value: await gameRef.loadSprite(
        'rocket_yellow.png',
      ),
    };
    // 添加返回按钮
    add(
      GIconButton(
        icon: Icons.close_rounded,
        size: Vector2(40, 40),
        iconColor: Colors.black87,
        iconSize: 32.0,
        onTap: () async {
          // 先保存游戏状态
          await saveGameState();
          //
          // 然后执行返回操作
          onExitPressed();
        },
        position: Vector2(30, safeAreaTop + 30),
      ),
    );
    // 声音按钮
    // add(
    //   SoundToggleButtonFlame(position: Vector2(size.x - 30, safeAreaTop + 30)),
    // );
    add(SettingButton(position: Vector2(size.x - 30, safeAreaTop + 30)));
    //刷新按钮
    refreshButton = RefreshButton(
      size: Vector2(45, 45),
      onUPdate: () {
        hammerBtn.updateBadge();
        penBtn.updateBadge();
        refreshButton.updateBadge();
      },
      position: Vector2(size.x - 55, safeAreaTop + 115),
      onbtnPressed: () {
        print('开始按钮被点击了');
        _removeHammerAnimation(); //移除锤子
        _removeColorSelectionWindow(); //移除改色
        return refreshGrids();
      },
    );
    add(refreshButton);
    //锤子按钮
    hammerBtn = HammerButton(
      size: Vector2(45, 45),
      position: Vector2(size.x - 55 - 55, safeAreaTop + 115),
      onUPdate: () {
        hammerBtn.updateBadge();
        penBtn.updateBadge();
        refreshButton.updateBadge();
      },
      onbtnPressed: () async {
        print('锤子按钮被点击了');
        _removeColorSelectionWindow();
        if (hammerBtn.isSelected) {
          _removeHammerAnimation();
        } else {
          // 随机选择一个方块
          final selectedBlock = _selectRandomBlock();
          if (selectedBlock != null) {
            // 显示锤子动画
            await _showHammerAnimation(selectedBlock);
          }
        }
        return true;
      },
    );
    add(hammerBtn);

    //改色笔按钮
    penBtn = PenButton(
      size: Vector2(45, 45),
      onUPdate: () {
        hammerBtn.updateBadge();
        penBtn.updateBadge();
        refreshButton.updateBadge();
      },
      position: Vector2(size.x - 55 - 55 - 55, safeAreaTop + 115),
      onbtnPressed: () {
        print('改色笔按钮被点击了');
        // 取消锤子状态（如果有选中的方块）
        _removeHammerAnimation();
        if (penBtn.isSelected) {
          _removeColorSelectionWindow();
          return OnTapType.normal;
        } else {
          // 随机选择一个星星方块
          final selectedStar = _selectRandomStar();
          if (selectedStar != null) {
            // 显示颜色选择窗口
            _showColorSelectionWindow(selectedStar);
          }
        }
        return OnTapType.yes;
      },
    );
    add(penBtn);
    // UI 起始 Y 轴位置
    double orgY = safeAreaTop + 10;
    double lineHeight = 30;
    double startX = 80; // 统一的起始X坐标
    double labelRightMargin = 10; // 标签和数值之间的间距
    final labelStyle = TextPaint(
      style: const TextStyle(color: Colors.white70, fontSize: 18),
    );
    final valueStyle = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
    final scoreStyle = TextPaint(
      style: const TextStyle(
        color: Colors.yellow,
        fontSize: 25,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(blurRadius: 3, color: Colors.black54, offset: Offset(1, 1)),
        ],
      ),
    );
    // Level - 使用动态位置计算
    String levelLabelText = '${'Level'.tr}:';
    TextPainter levelLabelPainter = labelStyle.toTextPainter(levelLabelText);
    levelLabelPainter.layout();
    add(
      levelLabel = TextComponent(
        text: levelLabelText,
        position: Vector2(startX, orgY),
        anchor: Anchor.topLeft,
        textRenderer: labelStyle,
      ),
    );
    double levelValueX = startX + levelLabelPainter.width + labelRightMargin;
    add(
      levelText = TextComponent(
        text: '${gameDataManager.getLevel()}',
        position: Vector2(levelValueX, orgY),
        anchor: Anchor.topLeft,
        textRenderer: valueStyle,
      ),
    );
    // Target - 使用动态位置计算
    String targetLabelText = '${'Target Score'.tr}:';
    TextPainter targetLabelPainter = labelStyle.toTextPainter(targetLabelText);
    targetLabelPainter.layout();
    add(
      targetLabel = TextComponent(
        text: targetLabelText,
        position: Vector2(startX, orgY + lineHeight),
        anchor: Anchor.topLeft,
        textRenderer: labelStyle,
      ),
    );
    double targetValueX = startX + targetLabelPainter.width + labelRightMargin;
    add(
      targetText = TextComponent(
        text:
            '${gameDataManager.getTargetScoreByLevel(gameDataManager.getLevel())}',
        position: Vector2(targetValueX, orgY + lineHeight),
        anchor: Anchor.topLeft,
        textRenderer: valueStyle,
      ),
    );
    // Score - 使用动态位置计算
    String scoreLabelText = '${'Score'.tr}:';
    TextPainter scoreLabelPainter = labelStyle.toTextPainter(scoreLabelText);
    scoreLabelPainter.layout();
    add(
      scoreLabel = TextComponent(
        text: scoreLabelText,
        position: Vector2(startX, orgY + lineHeight * 2),
        anchor: Anchor.topLeft,
        textRenderer: labelStyle,
      ),
    );
    double scoreValueX = startX + scoreLabelPainter.width + labelRightMargin;
    add(
      scoreText = TextComponent(
        text: '${gameDataManager.getScore()}',
        position: Vector2(scoreValueX, orgY + lineHeight * 2),
        anchor: Anchor.topLeft,
        textRenderer: scoreStyle,
      ),
    );
  }

  void _onCombo(int combo) {
    Vector2 position = Vector2(size.x / 2, safeAreaTop + 185);
    // SoundPool().playCombo();
    // if (combo <= 1) return;
    if (_comboTextComponent == null) {
      // 如果实例不存在，创建并添加到场景
      _comboTextComponent = ComboTextComponent(
        text: '$combo Combo!',
        position: position, // 或消除中心点
      );
      add(_comboTextComponent!);
    } else {
      // 如果实例已存在，使用updateCombo方法更新
      _comboTextComponent!.updateCombo(combo, position);
    }
  }

  void _onComboBreak(int combo) {
    Vector2 position = Vector2(size.x / 2, safeAreaTop + 185);
    SoundPool().playBubble();
    // 删除combo，添加淡出动画
    if (_comboTextComponent != null) {
      // 添加缩放和移动动画来实现淡出效果
      _comboTextComponent!.addAll([
        /// 1️⃣ 爆发 Punch
        ScaleEffect.to(
          Vector2.all(1.35),
          EffectController(duration: 0.12, curve: Curves.easeOutBack),
        ),

        /// 2️⃣ 快速缩小
        ScaleEffect.to(
          Vector2.all(0.5),
          EffectController(
            startDelay: 0.12,
            duration: 0.3,
            curve: Curves.easeIn,
          ),
          onComplete: () {
            // 动画完成后移除组件并展示分数
            remove(_comboTextComponent!);
            _comboTextComponent = null;
            // 展示分数
            addAndShowFlyScore(
              start: position,
              score: combo * 10,
              fontSize: 35,
            );
          },
        ),
      ]);
    } else {
      // 如果没有combo文本组件，直接展示分数
      addAndShowFlyScore(start: position, score: combo * 10, fontSize: 35);
    }
  }

  // 刷新当前关卡
  bool refreshGrids() {
    // 添加检查：如果关卡已开始(有过消除)并且剩余方块太少，则不允许刷新
    if (hasMadeElimination && getLeftStarNum() < rows * cols) {
      // 可以添加提示音效或其他反馈
      HuuuaDialog.show(
        title: "Tips".tr,
        message: "game_already_started_cannot_refresh".tr,
        cancelTitle: 'close'.tr,

        onCancel: () {},
      );
      return false; // 不执行刷新操作
    }
    currentlyHighlighted.clear(); // 清除当前高亮的方块

    // 先从场景中移除所有的旧星星方块
    for (var row in grid) {
      for (var block in row) {
        if (block != null) {
          remove(block);
        }
      }
    }

    // 2. 清空grid数组并重新初始化
    grid.clear(); // 清空整个grid数组

    // 4. 重新初始化游戏网格
    _initializeGrid();

    return true;
  }

  // 添加方法来保存游戏状态
  Future<void> saveGameState() async {
    // 只有当有过消除操作时才保存游戏状态
    if (!hasMadeElimination) {
      print('游戏尚未进行消除操作，不保存状态');
      return;
    }

    // 准备网格数据（将BlockType转换为数字）
    final List<List<int?>> gridData = [];
    for (final row in grid) {
      final List<int?> rowData = [];
      for (final block in row) {
        if (block == null) {
          rowData.add(null);
        } else {
          rowData.add(block.blockType.number);
        }
      }
      gridData.add(rowData);
    }

    // 调用GameDataManager的保存方法，传入刷新次数
    await gameDataManager.saveGameState(gridData, refreshCount: refreshCount);
  }

  // 添加方法来从保存的状态恢复游戏
  void _restoreGameState(Map<String, dynamic> savedState) {
    // 恢复游戏数据
    final level = savedState['level'] as int;
    final score = savedState['score'] as int;
    final gridData = savedState['grid'] as List<List<int?>>;

    // 更新游戏数据管理器
    gameDataManager.setLevel(level);
    gameDataManager.setScore(score);

    // 更新UI显示
    levelText.text = '$level';
    targetText.text = '${gameDataManager.getTargetScoreByLevel(level)}';
    scoreText.text = '$score';
    _updateScoreText();

    // 恢复网格状态
    _initializeGridFromSavedData(gridData);
  }

  // 添加方法从保存的数据初始化网格
  void _initializeGridFromSavedData(List<List<int?>> gridData) {
    grid.clear();

    for (int r = 0; r < rows; r++) {
      final List<BaseBlock?> rowList = [];
      for (int c = 0; c < cols; c++) {
        final blockTypeNumber = gridData[r][c];
        if (blockTypeNumber == null) {
          rowList.add(null);
          continue;
        }

        // 根据数字找到对应的BlockType
        final blockType = BlockType.values.firstWhere(
          (type) => type.number == blockTypeNumber,
          orElse: () => blockTypes[random.nextInt(blockTypes.length)],
        );

        // 创建方块
        final block = StarBlock(
          row: r,
          col: c,
          blockType: blockType,
          iconSprite: sprites[blockType.value]!,
          size: Vector2.all(blockSize),
          scene: this,
        );

        block.position = Vector2(
          c * (blockSize + padding) + blockSize / 2,
          r * (blockSize + padding) + offsetY + blockSize / 2,
        );

        add(block);
        rowList.add(block);
      }
      grid.add(rowList);
    }
  }

  /// 初始化 10x10 方块
  void _initializeGrid() {
    // 记录当前分数作为关卡开始分数（用于重新开始关卡时恢复分数）
    gameDataManager.setLevelStartScore(gameDataManager.getScore());

    for (int r = 0; r < rows; r++) {
      // 将StarBlock?改为BaseBlock?，与grid的类型声明保持一致
      final List<BaseBlock?> rowList = [];
      for (int c = 0; c < cols; c++) {
        // 使用BlockType枚举而不是字符串
        final blockType = blockTypes[random.nextInt(blockTypes.length)];
        final block = StarBlock(
          row: r,
          col: c,
          // 使用blockType参数替代type
          blockType: blockType,
          iconSprite: sprites[blockType.value]!,
          size: Vector2.all(blockSize),
          scene: this, // 传入当前场景引用
        );
        block.position = Vector2(
          c * (blockSize + padding) + blockSize / 2,
          r * (blockSize + padding) + offsetY + blockSize / 2,
        );
        add(block);
        rowList.add(block);
      }
      grid.add(rowList);
    }
  }

  /// 点击方块
  Future<void> handleTap(BaseBlock tappedBlock) async {
    // 如果正在处理消除动画/消除完成合并动画，直接返回，不响应点击
    if (isProcessingElimination || _isDropAnimating) {
      return;
    }

    try {
      // 使用blockType属性而不是type
      final blockType = tappedBlock.blockType;

      // 处理道具点击(改色笔，锤子)
      bool result = await _handleTapItemBlock(tappedBlock: tappedBlock);
      if (result) {
        return;
      }

      // 处理特殊方块点击(彩虹，闪电，火箭,雷达等)
      result = await _handleTapSpecialBlock(tappedBlock: tappedBlock);
      if (result) {
        return;
      }
      // 雷达消灭目标
      result = await _handleTapRadarSelectedBlock(tappedBlock: tappedBlock);
      if (result) {
        return;
      }
      final visited = <String>{};
      // 执行洪水填充算法，找到所有可消除的方块
      floodFill(
        r: tappedBlock.row,
        c: tappedBlock.col,
        blockType: tappedBlock.blockType,
        visited: visited,
      );

      //如果是双击设置
      if (GameDataManager().doubleTap) {
        // 同色方块高亮
        if (currentlyHighlighted.isEmpty) {
          //对同色方块进行高亮
          _highlightBlocks(visited);
        } else if (currentlyHighlighted.contains(
          '${tappedBlock.row},${tappedBlock.col}',
        )) {
          //进行消除操作
          await _executeElimination(tappedBlock);
        } else {
          //点击其他切换高亮
          _switchHighlight(visited);
        }
      } else {
        //单击设置

        //对同色方块进行高亮
        _highlightBlocks(visited);

        //进行消除操作
        await _executeElimination(tappedBlock);
      }
    } catch (e) {
      // 异常处理：确保清理状态，避免游戏出现异常
      print('Error in handleTap: $e');
      // 确保取消高亮状态
      for (final key in currentlyHighlighted) {
        final parts = key.split(',');
        final r = int.parse(parts[0]);
        final c = int.parse(parts[1]);
        if (r >= 0 && r < rows && c >= 0 && c < cols && grid[r][c] != null) {
          grid[r][c]!.setHighlight(false);
        }
      }
      currentlyHighlighted.clear();
      // 确保锤子和颜色选择窗口状态正确
      _removeHammerAnimation();
      _removeColorSelectionWindow();
      // 确保处理标志重置
      isProcessingElimination = false;
      hasMadeElimination = false;
    }
  }

  // 设置单个方块高亮
  void insertCurrentlyHighlighted({required int r, required int c}) {
    currentlyHighlighted.add('$r,$c');
    grid[r][c]?.setHighlight(true);
  }

  // 使用 flood fill 算法寻找相邻同色方块
  void floodFill({
    required int r,
    required int c,
    required BlockType blockType,
    required Set<String> visited,
  }) {
    if (r < 0 || r >= rows || c < 0 || c >= cols) return;
    final key = '$r,$c';
    if (visited.contains(key)) return;
    final block = grid[r][c];
    // 使用blockType比较而不是type
    if (block == null || block.blockType != blockType) return;
    visited.add(key);
    floodFill(r: r + 1, c: c, blockType: blockType, visited: visited);
    floodFill(r: r - 1, c: c, blockType: blockType, visited: visited);
    floodFill(r: r, c: c + 1, blockType: blockType, visited: visited);
    floodFill(r: r, c: c - 1, blockType: blockType, visited: visited);
  }

  /// 处理道具点击
  Future<bool> _handleTapItemBlock({required BaseBlock tappedBlock}) async {
    final blockType = tappedBlock.blockType;

    // 检查是否点击了被锤子选中的方块
    if (_hammerSelectedBlock == tappedBlock) {
      // 执行锤子消除逻辑
      await _handleHammerTap(tappedBlock);
      return true;
    }

    // 如果点击了其他方块，将锤子移动到点击的方块上方
    if (_hammerSelectedBlock != null && _hammerSelectedBlock != tappedBlock) {
      // 然后显示新的锤子动画
      await _showHammerAnimation(tappedBlock);
      return true;
    }

    // 处理颜色选择窗口移动逻辑：当窗口已打开且点击的是星星方块时，移动窗口到该方块上方
    if (penBtn.isSelected && _currentColorWindow != null) {
      // 检查点击的是否是星星方块（非特殊方块）
      if (tappedBlock.blockType == BlockType.blue_star ||
          tappedBlock.blockType == BlockType.red_star ||
          tappedBlock.blockType == BlockType.yellow_star ||
          tappedBlock.blockType == BlockType.green_star ||
          tappedBlock.blockType == BlockType.purple_star) {
        clearCurrentlyHilightted();

        insertCurrentlyHighlighted(r: tappedBlock.row, c: tappedBlock.col);
        // 移动窗口到点击的方块上方
        _currentColorWindow!.updateTargetBlock(tappedBlock);
        return true; // 阻止后续的方块选择逻辑
      }
    }
    return false;
  }

  void clearCurrentlyHilightted() {
    for (final key in currentlyHighlighted) {
      final parts = key.split(',');
      final r = int.parse(parts[0]);
      final c = int.parse(parts[1]);
      grid[r][c]?.setHighlight(false);
    }
    currentlyHighlighted.clear();
  }

  /// 处理雷达选中状态下点击星星进行激光消除
  Future<bool> _handleTapRadarSelectedBlock({
    required BaseBlock tappedBlock,
  }) async {
    final blockType = tappedBlock.blockType;
    if (radarBlock?.selected == true) {
      if (blockType.isStar) {
        SoundPool().playLaser(); //播放激光
        isProcessingElimination = true;
        // 执行激光消除逻辑
        final targetBlock = tappedBlock; //目标
        Vector2 radarPosition = radarBlock!.position; //雷达
        // 创建激光
        final laser = LaserBeamComponent(
          source: radarPosition,
          target: targetBlock.position,
          duration: 1,
        );
        add(laser);
        //次数减1
        radarBlock!.orderCount();
        // 短暂延迟以显示闪电效果
        await Future.delayed(Duration(milliseconds: 300));

        // 播放消灭音效
        SoundPool().playPop();

        // 添加爆炸粒子效果
        add(
          StarExplosionComponent(
            position: targetBlock.position + targetBlock.size / 2,
            totalCount: 50,
          ),
        );

        // 删除方块
        remove(targetBlock);
        grid[targetBlock.row][targetBlock.col] = null;

        if (targetBlock != null) {
          // 得分
          cleanBlockScoreFly(block: targetBlock, index: 1);
        }
        //检查次数
        if (radarBlock!.checkCount()) {
          grid[radarBlock!.row][radarBlock!.col] = null;
          remove(radarBlock!);
          radarBlock = null;
        }
        isProcessingElimination = false;
        _dropBlocksAndThenShift(); //执行算法结算
        return true;
      }
    }
    return false;
  }

  /// 处理特殊方块点击
  Future<bool> _handleTapSpecialBlock({required BaseBlock tappedBlock}) async {
    final blockType = tappedBlock.blockType;
    // 特殊处理所有火箭类型
    if (blockType == BlockType.rocket_blue ||
        blockType == BlockType.rocket_red ||
        blockType == BlockType.rocket_purple ||
        blockType == BlockType.rocket_green ||
        blockType == BlockType.rocket_yellow) {
      _removeColorSelectionWindow();
      _removeHammerAnimation();
      await _handleRocketTap(tappedBlock);
      return true;
    }

    // 盲盒方块点击处理
    if (blockType == BlockType.box) {
      _removeColorSelectionWindow();
      _removeHammerAnimation();
      await _handleBoxTap(tappedBlock);
      return true;
    }

    // 点击彩虹效果
    if (blockType == BlockType.rainbow) {
      _removeColorSelectionWindow();
      _removeHammerAnimation();
      await _handleRainbowTap(tappedBlock);
      return true;
    }

    // 点击闪电
    if (blockType == BlockType.lightning) {
      _removeColorSelectionWindow();
      _removeHammerAnimation();
      await _handleLightningTap(tappedBlock);
      return true;
    }

    // 点击雷达
    if (blockType == BlockType.radar) {
      _removeColorSelectionWindow();
      _removeHammerAnimation();
      await _handleRadarTap(tappedBlock);
      return true;
    }
    return false;
  }

  /// 创建特殊方块
  void _handleCreateSpecialBlock({required BaseBlock tappedBlock}) {
    // 一次性消灭大于12个才生成火箭方块
    if (currentlyHighlighted.length >= 12) {
      // _generateBoxBlock(tappedBlock.row, tappedBlock.col);
      _generateRocketBlock(
        tappedBlock.row,
        tappedBlock.col,
        tappedBlock.blockType,
      );
    }
    //彩虹
    if (currentlyHighlighted.length >= 2) {
      randomRainbowBlock(
        tappedBlock.row,
        tappedBlock.col,
        currentlyHighlighted.length,
      );
    }
    // 闪电
    if (currentlyHighlighted.length >= 2) {
      randomLightningBlock(
        tappedBlock.row,
        tappedBlock.col,
        tappedBlock.blockType,
        currentlyHighlighted.length,
      );
    }
    // 盲盒
    if (currentlyHighlighted.length >= 2) {
      checkGenerateBox(
        currentlyHighlighted.length,
        tappedBlock.row,
        tappedBlock.col,
      );
    }
    //雷达
    if (currentlyHighlighted.length >= 2) {
      randomRadarBlock(
        tappedBlock.row,
        tappedBlock.col,
        currentlyHighlighted.length,
      );
    }
  }

  double getProbability({
    required int startCount,
    required int endCount,
    required double minPb,
    required double maxPb,
    required int count,
  }) {
    const int startCount = 3; // 从 3 个开始触发概率
    const int endCount = 15; // 达到最大概率的消除数量
    final double minProbability = HuuuaConfig.isDebug ? 0.8 : 0.01; // 最低概率
    final double maxProbability = HuuuaConfig.isDebug ? 0.8 : 0.02; // 最大概率

    if (count < startCount) return 0;

    double t = (count - startCount) / (endCount - startCount);
    t = t.clamp(0.0, 1.0);

    // 平滑增长曲线（ease-out）
    double curve = 1 - pow(2, -5 * t).toDouble();

    // 计算最终概率
    double probability =
        minProbability + (maxProbability - minProbability) * curve;
    return probability;
  }

  void checkGenerateBox(int count, int row, int col) {
    double probability = getProbability(
      startCount: 3,
      endCount: 15,
      minPb: HuuuaConfig.isDebug ? 0.8 : 0.01,
      maxPb: HuuuaConfig.isDebug ? 0.8 : 0.02,
      count: count,
    );

    if (_rnd.nextDouble() < probability) {
      _generateBoxBlock(row, col);
    }
  }

  // 随机雷达方块
  void randomRadarBlock(int row, int col, int count) {
    if (radarBlock != null) {
      return;
    }

    double probability = getProbability(
      startCount: 2,
      endCount: 15,
      minPb: HuuuaConfig.isDebug ? 0.01 : 0.01,
      maxPb: HuuuaConfig.isDebug ? 0.01 : 0.035,
      count: count,
    );

    if (_rnd.nextDouble() < probability) {
      _generateRadarBlock(row, col);
    }
  }

  // 随机彩虹方块
  void randomRainbowBlock(int row, int col, int count) {
    // 彩虹方块生成概率：调试模式80%，正常模式1%

    double probability = getProbability(
      startCount: 2,
      endCount: 15,
      minPb: HuuuaConfig.isDebug ? 0.01 : 0.01,
      maxPb: HuuuaConfig.isDebug ? 0.01 : 0.035,
      count: count,
    );

    if (_rnd.nextDouble() < probability) {
      _generateRainbowBlock(row, col);
    }
  }

  // 随机闪电方块
  void randomLightningBlock(
    int row,
    int col,
    BlockType targetType,
    int targetCount,
  ) {
    if (lightningBlock != null) {
      return;
    }
    // 彩虹方块生成概率：调试模式80%，正常模式1%

    double probability = getProbability(
      startCount: 2,
      endCount: 15,
      minPb: HuuuaConfig.isDebug ? 0.01 : 0.01,
      maxPb: HuuuaConfig.isDebug ? 0.01 : 0.035,
      count: targetCount,
    );

    if (_rnd.nextDouble() < probability) {
      _generateLightningBlock(row, col, targetType, targetCount);
    }
  }

  void _dropBlocksAndThenShift() {
    if (_isDropAnimating) return;
    _isDropAnimating = true;

    int movingBlocks = 0;
    List<Completer<void>> dropCompleters = [];

    for (int c = 0; c < cols; c++) {
      int emptyRow = rows - 1;

      for (int r = rows - 1; r >= 0; r--) {
        if (grid[r][c] != null) {
          if (r != emptyRow) {
            final block = grid[r][c]!;

            // ===== 数据更新 =====
            grid[emptyRow][c] = block;
            grid[r][c] = null;
            block.row = emptyRow;
            block.col = c;

            movingBlocks++;

            final distance = (emptyRow - r).abs();
            final duration = (0.15 + distance * 0.1)
                .clamp(0.15, 0.4)
                .toDouble();

            final targetX = c * (blockSize + padding) + blockSize / 2;
            final targetY =
                emptyRow * (blockSize + padding) + offsetY + blockSize / 2;

            final completer = Completer<void>();
            dropCompleters.add(completer);

            block.add(
              MoveEffect.to(
                  Vector2(targetX, targetY),
                  EffectController(duration: duration, curve: Curves.bounceOut),
                )
                ..onComplete = () {
                  movingBlocks--;
                  if (movingBlocks == 0) {
                    Future.wait(dropCompleters.map((c) => c.future)).then((_) {
                      _shiftColumnsLeft();
                    });
                  }
                  completer.complete();
                },
            );
          }

          emptyRow--;
        }
      }
    }

    if (movingBlocks > 0) {
      SoundPool().playDroppopPop();
    }

    if (movingBlocks == 0) {
      _shiftColumnsLeft();
    }
  }

  /// 判断关卡是否已经没有可消除
  /// 判断关卡是否结束
  /// 检查游戏网格中是否还存在可消除的星星组合（相同颜色的相邻星星）
  /// 如果没有找到可消除的组合，则关卡结束
  bool isLevelEnd() {
    // 遍历游戏网格中的每个格子
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        // 获取当前位置的星星方块
        final star = grid[row][col];

        // 如果当前位置为空，跳过此位置
        if (star == null) continue;

        // 如果不是StarBlock类型，跳过判断（例如彩虹方块等特殊类型）
        if (star is! StarBlock) continue;

        // 检查下方的星星方块
        int checkRow = row + 1;
        if (checkRow < rows) {
          final checkStar = grid[checkRow][col];
          // 如果下方有星星且颜色与当前星星相同，则存在可消除组合，关卡未结束
          if (checkStar != null && checkStar.blockType == star.blockType) {
            return false; // 发现可消除组合，返回false表示关卡未结束
          }
        }

        // 检查右侧的星星方块
        int checkCol = col + 1;
        if (checkCol < cols) {
          final checkStar = grid[row][checkCol];
          // 如果右侧有星星且颜色与当前星星相同，则存在可消除组合，关卡未结束
          if (checkStar != null && checkStar.blockType == star.blockType) {
            return false; // 发现可消除组合，返回false表示关卡未结束
          }
        }
      }
    }

    // 遍历完所有格子都没有找到可消除的组合，返回true表示关卡结束
    return true;
  }

  void checkLevelEnd() async {
    //遍历消除特殊方块
    if (isLevelEnd()) {
      comboManager.breakCombo(); //关卡结束，连击次数转化成分数

      // 关卡结束时，消除所有非StarBlock类型的方块
      currentlyHighlighted.clear();

      // 遍历网格找出所有非StarBlock类型的方块
      for (int row = 0; row < rows; row++) {
        for (int col = 0; col < cols; col++) {
          final block = grid[row][col];
          if (block != null && block is! StarBlock) {
            // 将非StarBlock方块添加到高亮列表
            currentlyHighlighted.add('$row,$col');
          }
        }
      }

      // 如果有非StarBlock方块需要消除
      if (currentlyHighlighted.isNotEmpty) {
        hasMadeElimination = true;

        _currentlyHighlightedScoreFlying(); // 分数动画

        // 添加爆炸效果并移除非StarBlock方块
        for (final key in currentlyHighlighted) {
          final parts = key.split(',');
          final r = int.parse(parts[0]);
          final c = int.parse(parts[1]);
          final block = grid[r][c];

          if (block != null) {
            // 添加爆炸粒子效果
            add(
              StarExplosionComponent(
                position: block.position + block.size / 2,
                totalCount: 50,
              ),
            );

            // 播放销毁音效
            SoundPool().playPop();
            // 删除方块
            remove(block);
            grid[r][c] = null;
          }

          // 每个方块间隔 100ms
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // 清空高亮列表
        currentlyHighlighted.clear();
      }
    }

    if (isLevelEnd()) {
      final numLeft = getLeftStarNum();
      int lastBonus = 0;

      // 先显示剩余
      final leftMessage = TextComponent(
        text: "@numleft stars left".trParams({'numleft': '$numLeft'}),
        position: size / 2 + Vector2(0, 60),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.orangeAccent,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(blurRadius: 4, color: Colors.black, offset: Offset(2, 2)),
            ],
          ),
        ),
      );
      add(leftMessage);

      // 固定显示 "奖励:" 在左边
      final rewardLabel = TextComponent(
        text: '${'Bonus'.tr}:',
        position: size / 2 + Vector2(0, 0),
        anchor: Anchor.centerRight,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.yellow,
            fontSize: 30,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(blurRadius: 4, color: Colors.black, offset: Offset(2, 2)),
            ],
          ),
        ),
      );
      add(rewardLabel);

      // 动态奖励数字在右边
      final bonusValue = TextComponent(
        text: '0',
        position: size / 2 + Vector2(6, 0),
        anchor: Anchor.centerLeft,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.yellow,
            fontSize: 30,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(blurRadius: 4, color: Colors.black, offset: Offset(2, 2)),
            ],
          ),
        ),
      );
      add(bonusValue);

      // 记录所有剩余星星
      List<Vector2> allStars = [];
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (grid[r][c] != null) {
            allStars.add(Vector2(r.toDouble(), c.toDouble()));
          }
        }
      }

      final rand = Random();
      final maxLoop = min(numLeft, gameDataManager.leftNumScoreMap.length);

      for (int i = 0; i <= maxLoop; i++) {
        final bonusScore = gameDataManager.getScoreByLeftNum(i);

        // 随机移除一部分星星
        int numToRemove = (allStars.length / (maxLoop - i + 1)).ceil();
        for (int j = 0; j < numToRemove && allStars.isNotEmpty; j++) {
          int idx = rand.nextInt(allStars.length);
          final pos = allStars.removeAt(idx);
          int r = pos.x.toInt();
          int c = pos.y.toInt();

          final block = grid[r][c];
          if (block != null) {
            add(
              StarExplosionComponent(
                position: block.position + block.size / 2,
                totalCount: 30,
              ),
            );
            SoundPool().playPop();
            remove(block);
            grid[r][c] = null;
          }
        }

        // 更新右边的奖励数字
        bonusValue.text = '$bonusScore';
        bonusValue.add(
          MoveEffect.by(
            Vector2(0, 1),
            EffectController(
              duration: 0.2,
              reverseDuration: 0.2,
              alternate: true,
            ),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 120));

        lastBonus = bonusScore;
      }

      final totalScore = gameDataManager.getScore() + lastBonus;

      final startPos = Vector2(size.x / 2 + 6, size.y / 2 - 10);

      // 先生成一个分身数字
      final flyClone = TextComponent(
        text: '+$lastBonus',
        position: startPos.clone(),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.orange,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(blurRadius: 4, color: Colors.black, offset: Offset(2, 2)),
            ],
          ),
        ),
      );
      add(flyClone);
      // 先往上浮一点
      flyClone.add(
        MoveEffect.to(
          startPos - Vector2(0, 30),
          EffectController(duration: 0.4),
          onComplete: () {
            // 播放飞翔音效
            // 到顶后再飞向 Score
            add(
              FloatingScoreComponent(
                start: flyClone.position.clone(),
                end:
                    scoreText.absoluteCenter + Vector2(0, scoreText.size.y / 2),
                score: lastBonus,
                onArrived: () {
                  print("增加分数");
                  SoundPool().playScore(); //播放加分音效
                  gameDataManager.setScore(totalScore);
                  _updateScoreText();
                  Future.delayed(const Duration(milliseconds: 50), () {
                    leftMessage.removeFromParent();
                    rewardLabel.removeFromParent();
                    bonusValue.removeFromParent();
                  });

                  // 添加1秒延迟
                  Future.delayed(const Duration(seconds: 1), () {
                    if (isGameOver()) {
                      changeToGameOver();
                    } else {
                      changeToNextLevel();
                    }
                  });
                },
              ),
            );

            // 删除分身
            flyClone.removeFromParent();
          },
        ),
      );
    }
  }

  /// 返回还剩多少未消除
  int getLeftStarNum() {
    int count = 0;
    for (final row in grid) {
      for (final block in row) {
        if (block != null) {
          count++;
        }
      }
    }
    return count;
  }

  /// 判断是否游戏结束（没达到目标分数）
  bool isGameOver() {
    final level = gameDataManager.getLevel();
    final target = gameDataManager.getTargetScoreByLevel(level);
    final score = gameDataManager.getScore();
    return score < target;
  }

  Future<void> changeToGameOver() async {
    SoundPool().playGameOver();

    // // 游戏结束
    // gameOverComponents = GameOverComponent(
    //   text: 'Game Over!'.tr,
    //   onComplete: () {
    //     print('GameOver 动画完成');
    //   },
    //   position: size / 2,
    // );
    // add(gameOverComponents);
    //
    // // 开始按钮
    // newGameButton = GTextButton(
    //   position: Vector2(size.x / 2, size.y / 4 * 3),
    //   size: Vector2(200, 65), // 方形，圆角会按 size 自动缩放
    //   text: 'New Game'.tr,
    //   textStyle: TextStyle(
    //     fontSize: 25,
    //     fontWeight: FontWeight.bold,
    //     height: 1.1,
    //     letterSpacing: 4.5, // 新增：文字间隔
    //     color: const Color(0xFFFDF7E6),
    //   ),
    //   textScale: 1.0,
    //   onTap: () {
    //     // newGame(); // 直接在当前页面重新开始游戏
    //
    //   },
    // );
    //
    // add(newGameButton);
    isGameOverUIActive = true;
    GameoverDialog.show(
      onRestart: () {
        newGame(); // 重新开始
      },
      onRevive: () {
        ReviveDialog.show(
          onRestart: () {
            ReviveSuccessDialog.show(
              onRestart: () {
                restartCurrentLevel(); // 当前关卡重启
              },
              onCancel: () {},
            );
          },
          onCancel: () {
            //新游戏
            newGame();
          },
        );
      },
    );
  }

  void newGame() {
    // 清除保存的游戏状态
    gameDataManager.clearGameState();
    SoundPool().playStartGame();
    if (isGameOverUIActive) {
      // remove(newGameButton);
      // remove(gameOverComponents);
      isGameOverUIActive = false;
    }
    // 1. 重置游戏数据
    GameDataManager().dispose(); // 重置关卡和分数
    hasShownLevelCompleteMessage = false; // 重置关卡完成消息标记
    currentlyHighlighted.clear(); // 清除当前高亮的方块

    // 2. 清空grid数组并重新初始化
    grid.clear(); // 清空整个grid数组

    // 4. 重新初始化游戏网格
    _initializeGrid();

    // 5. 更新UI显示
    _updateScoreText();
    levelText.text = '${GameDataManager().getLevel()}';
    targetText.text =
        '${GameDataManager().getTargetScoreByLevel(GameDataManager().getLevel())}';
  }

  /// 重新开始当前关卡
  ///
  /// 从总分中减去当前关卡获得的分数，恢复到上一关完成的状态，
  /// 然后重新初始化当前关卡。
  void restartCurrentLevel() {
    // 1. 计算当前关卡获得的分数并从总分中减去
    final levelStartScore = gameDataManager.levelStartScore;
    final currentScore = gameDataManager.getScore();
    final levelScore = currentScore - levelStartScore;

    // 如果当前关卡有获得分数，则减去
    if (levelScore > 0) {
      gameDataManager.setScore(levelStartScore);
    }

    // 2. 清除所有方块
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (grid[r][c] != null) {
          remove(grid[r][c]!);
          grid[r][c] = null;
        }
      }
    }
    grid.clear();

    // 3. 清除高亮状态和其他状态
    currentlyHighlighted.clear();
    hasMadeElimination = false;
    hasShownLevelCompleteMessage = false;

    // 4. 重新初始化当前关卡
    _initializeGrid();

    // 5. 更新UI显示
    _updateScoreText();
    scoreText.text = '${gameDataManager.getScore()}';

    // 播放重新开始音效
    SoundPool().playStartGame();
  }

  void changeToNextLevel() {
    SoundPool().playNextLevel();

    // 中间显示恭喜提示 - 动态调整字体大小以适应屏幕宽度
    final congratsText = '🎉 ${'Congratulations! Next Level!'.tr}';
    // 获取屏幕宽度并留出一些边距
    final maxWidth = size.x * 0.9;
    // 初始字体大小
    double fontSize = 36;

    // 创建TextPainter来测量文本宽度
    final textPainter = TextPainter(
      text: TextSpan(
        text: congratsText,
        style: TextStyle(
          color: Colors.yellow,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    // 动态调整字体大小直到文本宽度小于最大允许宽度
    while (textPainter.width > maxWidth && fontSize > 12) {
      fontSize -= 2;
      textPainter.text = TextSpan(
        text: congratsText,
        style: TextStyle(
          color: Colors.yellow,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
    }

    final congratsMessage = TextComponent(
      text: congratsText,
      position: size / 2,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.yellow,
          fontSize: fontSize, // 使用调整后的字体大小
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(blurRadius: 4, color: Colors.black, offset: Offset(2, 2)),
          ],
        ),
      ),
    );
    add(congratsMessage);

    // 轻微上下浮动动画
    congratsMessage.add(
      MoveEffect.by(
        Vector2(0, -20),
        EffectController(duration: 0.4, reverseDuration: 0.4, alternate: true),
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      final nextLevel = gameDataManager.getLevel() + 1;
      final nextTarget = gameDataManager.getTargetScoreByLevel(nextLevel);

      // === Level 标签 + 数值 ===
      final levelLabel = TextComponent(
        text: '${'Level'.tr}:',
        position: size / 2 + Vector2(-40, -120),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.cyan,
            fontSize: 25,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(blurRadius: 4, color: Colors.black, offset: Offset(2, 2)),
            ],
          ),
        ),
      );
      add(levelLabel);

      final levelValue = TextComponent(
        text: '$nextLevel',
        position: size / 2 + Vector2(40, -120),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.cyan,
            fontSize: 25,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(blurRadius: 4, color: Colors.black, offset: Offset(2, 2)),
            ],
          ),
        ),
      );
      add(levelValue);

      // === Target 标签 + 数值 ===
      // 使用动态位置计算确保标签和数值对齐
      String targetLabelText = '${'Target Score'.tr}:';
      TextPaint textStyle = TextPaint(
        style: const TextStyle(
          color: Colors.orangeAccent,
          fontSize: 25,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(blurRadius: 4, color: Colors.black, offset: Offset(2, 2)),
          ],
        ),
      );

      // 计算标签文本宽度
      TextPainter targetLabelPainter = textStyle.toTextPainter(targetLabelText);
      targetLabelPainter.layout();

      // 标签和数值之间的间距
      double labelValueSpacing = 10;

      // 计算整个组合的宽度
      double totalWidth =
          targetLabelPainter.width +
          labelValueSpacing +
          textStyle.toTextPainter('$nextTarget').width;

      // 计算起始X坐标以确保整体居中
      double startX = (size.x - totalWidth) / 2;

      // 创建并添加标签
      final targetLabel = TextComponent(
        text: targetLabelText,
        position: Vector2(startX, size.y / 2 - 85),
        anchor: Anchor.centerLeft,
        textRenderer: textStyle,
      );
      add(targetLabel);

      // 创建并添加数值，位置基于标签宽度动态计算
      final targetValue = TextComponent(
        text: '$nextTarget',
        position: Vector2(
          startX + targetLabelPainter.width + labelValueSpacing,
          size.y / 2 - 85,
        ),
        anchor: Anchor.centerLeft,
        textRenderer: textStyle,
      );
      add(targetValue);

      // === 果冻放大缩小动画（不淡出） ===
      void jellyEffect(TextComponent comp) {
        comp.add(
          ScaleEffect.to(
            Vector2.all(1.5),
            EffectController(duration: 0.2, curve: Curves.easeOut),
            onComplete: () {
              comp.add(
                ScaleEffect.to(
                  Vector2.all(0.8),
                  EffectController(duration: 0.2, curve: Curves.easeInOut),
                  onComplete: () {
                    comp.add(
                      ScaleEffect.to(
                        Vector2.all(1.0),
                        EffectController(
                          duration: 0.2,
                          curve: Curves.easeInOut,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      }

      jellyEffect(levelValue);
      jellyEffect(targetValue);

      // 延迟 2 秒后进入下一关
      Future.delayed(const Duration(seconds: 2), () {
        congratsMessage.removeFromParent();
        levelLabel.removeFromParent();
        targetLabel.removeFromParent();
        levelValue.removeFromParent();
        targetValue.removeFromParent();
        gotoNextLevel();
      });
    });
  }

  /// 左移列操作
  /// 将非空列向左移动，填补空列产生的空隙
  /// 确保所有非空列都紧密排列在左侧，提高游戏区域的利用效率
  void _shiftColumnsLeft() {
    int targetCol = 0;
    List<Completer<void>> shiftCompleters = [];

    for (int c = 0; c < cols; c++) {
      bool isEmpty = true;
      for (int r = 0; r < rows; r++) {
        if (grid[r][c] != null) {
          isEmpty = false;
          break;
        }
      }

      if (!isEmpty) {
        if (targetCol != c) {
          for (int r = 0; r < rows; r++) {
            final block = grid[r][c];
            if (block != null) {
              grid[r][targetCol] = block;
              grid[r][c] = null;
              block.col = targetCol;

              final completer = Completer<void>();
              shiftCompleters.add(completer);

              block.add(
                MoveEffect.to(
                    Vector2(
                      targetCol * (blockSize + padding) + blockSize / 2,
                      block.row * (blockSize + padding) +
                          offsetY +
                          blockSize / 2,
                    ),
                    EffectController(duration: 0.2),
                  )
                  ..onComplete = () {
                    completer.complete();
                  },
              );
            }
          }
        }
        targetCol++;
      }
    }

    // 清除右侧多余的列
    for (int c = targetCol; c < cols; c++) {
      for (int r = 0; r < rows; r++) {
        grid[r][c] = null;
      }
    }

    if (shiftCompleters.isEmpty) {
      _isDropAnimating = false;
      checkLevelEnd();
    } else {
      Future.wait(shiftCompleters.map((c) => c.future)).then((_) {
        _isDropAnimating = false;
        checkLevelEnd();
      });
    }
  }

  //
  void showPraise(int num) {
    String image = "";
    String sound = "";
    if (num >= 14) {
      image = 'excellent.png';
      sound = 'excellent.mp3';
    } else if (num >= 12) {
      image = 'perfect.png';
      sound = 'perfect.mp3';
    } else if (num >= 10) {
      image = 'great.png';
      sound = 'great.mp3';
    } else if (num >= 8) {
      image = 'nice.png';
      sound = 'nice.mp3';
    } else if (num >= 6) {
      image = 'good.png';
      sound = 'good.mp3';
    }
    if (sound.isNotEmpty) {
      SoundPool().playPraise(sound);
    }
    if (image.isNotEmpty) {
      add(PraiseEffectComponent(imagePath: image, position: size / 2));
    }
  }

  // 添加方法来更新刷新次数的显示
  void updateRefreshCountText() {
    if (refreshCountText != null) {
      refreshCountText!.text = '$refreshCount';
    }
  }

  /// 更新 UI 文本 + 达到目标分数提示
  void _updateScoreText() {
    scoreText.text = '${gameDataManager.getScore()}';
    targetText.text =
        '${gameDataManager.getTargetScoreByLevel(gameDataManager.getLevel())}';

    // 获取当前分数和目标分数
    final currentScore = gameDataManager.getScore();
    final targetScore = gameDataManager.getTargetScoreByLevel(
      gameDataManager.getLevel(),
    );

    // 根据分数关系设置颜色
    if (currentScore < targetScore) {
      scoreText.textRenderer = TextPaint(
        style: const TextStyle(
          color: Colors.red,
          fontSize: 25,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(blurRadius: 3, color: Colors.black54, offset: Offset(1, 1)),
          ],
        ),
      );
    } else {
      scoreText.textRenderer = TextPaint(
        style: const TextStyle(
          color: Colors.green,
          fontSize: 25,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(blurRadius: 3, color: Colors.black54, offset: Offset(1, 1)),
          ],
        ),
      );
    }

    if (!hasShownLevelCompleteMessage &&
        gameDataManager.getScore() >= targetScore) {
      hasShownLevelCompleteMessage = true;
      _showLevelCompleteMessage();
    }
  }

  /// 达成分数的动画提示
  void _showLevelCompleteMessage() {
    SoundPool().playComplete();
    final message = TextComponent(
      text: '🎉 ${'Target Reached!'.tr}',
      position: size / 2,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 34,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(blurRadius: 4, color: Colors.black, offset: Offset(2, 2)),
          ],
        ),
      ),
    );
    add(message);

    message.add(
      MoveEffect.by(
        Vector2(0, -20),
        EffectController(duration: 0.3, reverseDuration: 0.3, alternate: true),
      ),
    );
    Future.delayed(const Duration(milliseconds: 2000), () {
      message.removeFromParent();
    });
  }

  /// 下一关重置网格
  void gotoNextLevel() {
    hasShownLevelCompleteMessage = false;

    // 更新关卡和分数
    gameDataManager.setLevel(gameDataManager.getLevel() + 1);

    // 记录当前分数作为新关卡的开始分数
    gameDataManager.setLevelStartScore(gameDataManager.getScore());

    levelText.text = '${gameDataManager.getLevel()}';
    targetText.text =
        '${gameDataManager.getTargetScoreByLevel(gameDataManager.getLevel())}';
    scoreText.text = '${gameDataManager.getScore()}';

    // === 果冻动画方法 ===
    void jellyEffect(TextComponent comp) {
      comp.add(
        ScaleEffect.to(
          Vector2.all(1.5), // 放大
          EffectController(duration: 0.2, curve: Curves.easeOut),
          onComplete: () {
            comp.add(
              ScaleEffect.to(
                Vector2.all(0.8), // 缩小
                EffectController(duration: 0.2, curve: Curves.easeInOut),
                onComplete: () {
                  comp.add(
                    ScaleEffect.to(
                      Vector2.all(1.0), // 回到原始大小
                      EffectController(duration: 0.2, curve: Curves.easeInOut),
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
    }

    // 给 levelText 和 targetText 添加果冻动画
    jellyEffect(levelText);
    jellyEffect(targetText);
    SoundPool().playDingdong();

    // 清理旧方块并初始化新关卡
    for (final row in grid) {
      for (final block in row) {
        if (block != null && block.isMounted) {
          remove(block);
        }
      }
    }
    grid.clear();
    _initializeGrid();
  }

  /// 盲盒
  void _generateBoxBlock(int row, int col) {
    BoxBlock.createAndInitialize(
      row,
      col,
      this,
      blockSize,
      padding,
      offsetY,
      BlockType.box,
    );
  }

  /// 闪电
  Future<void> _generateLightningBlock(
    int row,
    int col,
    BlockType targetType,
    int targetCount,
  ) async {
    lightningBlock = await LightningBlock.createAndInitialize(
      row,
      col,
      this,
      blockSize,
      padding,
      offsetY,
      BlockType.lightning,
      targetType,
      targetCount,
    );
  }

  /// 彩虹
  void _generateRainbowBlock(int row, int col) {
    RainbowBlock.createAndInitialize(
      row,
      col,
      this,
      blockSize,
      padding,
      offsetY,
      BlockType.rainbow,
    );
  }

  /// 雷达
  Future<void> _generateRadarBlock(int row, int col) async {
    radarBlock = await RadarBlock.createAndInitialize(
      row,
      col,
      this,
      blockSize,
      padding,
      offsetY,
      BlockType.radar,
    );
  }

  /// 火箭生成方法，支持五种颜色
  void _generateRocketBlock(int row, int col, BlockType blockType) {
    BlockType rocketType = BlockType.rocket_blue;

    // 根据火箭类型创建相应的火箭方块
    switch (blockType) {
      case BlockType.blue_star:
        rocketType = BlockType.rocket_blue;
        break;
      case BlockType.red_star:
        rocketType = BlockType.rocket_red;
        break;
      case BlockType.purple_star:
        rocketType = BlockType.rocket_purple;
        break;
      case BlockType.green_star:
        rocketType = BlockType.rocket_green;
        break;
      case BlockType.yellow_star:
        rocketType = BlockType.rocket_yellow;
        break;
      default:
        rocketType = BlockType.rocket_blue;
    }
    RocketBlock.createAndInitialize(
      row,
      col,
      this,
      blockSize,
      padding,
      offsetY,
      rocketType,
    );
  }

  /// 雷达点击
  Future<void> _handleRadarTap(BaseBlock tappedBlock) async {
    // 设置为正在处理消除状态
    isProcessingElimination = true;

    // 播放点击音效
    SoundPool().playSelect();

    if (tappedBlock is RadarBlock) {
      // 雷达选中状态更新
      tappedBlock.changeSelected();
    }

    isProcessingElimination = false;
    _dropBlocksAndThenShift(); //执行算法结算
  }

  Future<void> _handleLightningTap(BaseBlock tappedBlock) async {
    // 设置为正在处理消除状态
    isProcessingElimination = true;

    // 播放点击音效
    SoundPool().playSelect();

    if (tappedBlock is LightningBlock) {
      LightningBlock _tapedblock = tappedBlock;
      final targetType = _tapedblock.targetType; //目标方块
      final targetCount = _tapedblock.targetCount; //目标数量

      // 当前点击的闪电方块位置
      final currentRow = _tapedblock.row;
      final currentCol = _tapedblock.col;

      // 收集所有目标类型的方块及其与当前方块的距离
      List<_TargetBlockInfo> targets = [];

      for (int row = 0; row < rows; row++) {
        for (int col = 0; col < cols; col++) {
          final block = grid[row][col];
          if (block != null && block.blockType == targetType) {
            // 计算曼哈顿距离
            final distance =
                (row - currentRow).abs() + (col - currentCol).abs();
            targets.add(_TargetBlockInfo(block: block, distance: distance));
          }
        }
      }

      // 按照距离由近到远排序
      targets.sort((a, b) => a.distance.compareTo(b.distance));

      // 选择最近的targetCount个方块
      final selectedTargets = targets.take(targetCount).toList();

      // 当前闪电链的起点（初始为点击的闪电方块）
      Vector2 currentStart = _tapedblock.position;

      int index = 0;

      // 最后移除当前点击的闪电方块
      SoundPool().playPop();
      add(
        StarExplosionComponent(
          position: _tapedblock.position + _tapedblock.size / 2,
          totalCount: 50,
        ),
      );
      remove(_tapedblock);
      lightningBlock = null;
      // 得分
      cleanBlockScoreFly(block: _tapedblock, index: index);

      // 依次创建闪电链并消灭目标方块
      for (final targetInfo in selectedTargets) {
        final targetBlock = targetInfo.block;
        SoundPool().playLightning(); //播放闪电
        // 创建闪电链
        final lightningChain = LightningComponent(
          start: currentStart,
          end: targetBlock.position,

          duration: 1,
        );

        // 添加闪电链到场景
        add(lightningChain);

        // 短暂延迟以显示闪电效果
        await Future.delayed(Duration(milliseconds: 300));

        // 播放消灭音效
        SoundPool().playPop();

        // 添加爆炸粒子效果
        add(
          StarExplosionComponent(
            position: targetBlock.position + targetBlock.size / 2,
            totalCount: 50,
          ),
        );

        // 删除方块
        remove(targetBlock);
        grid[targetBlock.row][targetBlock.col] = null;

        // 更新当前起点为下一个闪电链的起点
        currentStart = targetBlock.position;

        if (targetBlock != null) {
          // 得分
          cleanBlockScoreFly(block: targetBlock, index: index);
          index++;
        }

        // 短暂延迟以显示连续效果
        await Future.delayed(Duration(milliseconds: 50));
      }

      grid[currentRow][currentCol] = null;
    }

    isProcessingElimination = false;
    _dropBlocksAndThenShift(); //执行算法结算
  }

  // 被消除的方块得分和动画
  void cleanBlockScoreFly({
    required BaseBlock block, //方块
    required int index, //第几个
  }) {
    int score = (5 + index * 10);

    addAndShowFlyScore(start: block.position, score: score, delay: index * 0.2);
    // add(
    //   FloatingScoreComponent(
    //     start: block.position,
    //     end: scoreText.absoluteCenter + Vector2(0, scoreText.size.y / 2),
    //     score: score,
    //     onArrived: () {
    //       SoundPool().playScore(); //播放加分音效
    //       gameDataManager.setScore(gameDataManager.getScore() + score);
    //       _updateScoreText();
    //     },
    //     delay: index * 0.2,
    //   ),
    // );
  }

  // 得分并显示得分动画
  void addAndShowFlyScore({
    required Vector2 start,
    Vector2? end,
    required int score,
    double delay = 0.0,
    double? fontSize,
  }) {
    add(
      FloatingScoreComponent(
        start: start,
        end: end ?? scoreText.absoluteCenter + Vector2(0, scoreText.size.y / 2),
        score: score,
        fontSize: fontSize,
        onArrived: () {
          SoundPool().playScore(); //播放加分音效
          gameDataManager.setScore(gameDataManager.getScore() + score);
          _updateScoreText();
        },
        delay: delay,
      ),
    );
  }

  /// 处理彩虹点击
  Future<void> _handleRainbowTap(BaseBlock tappedBlock) async {
    // 设置为正在处理消除状态
    isProcessingElimination = true;

    // 播放点击音效
    SoundPool().playSelect();
    SoundPool().playRainbow();
    // 获取彩虹方块的位置
    int rainbowRow = tappedBlock.row;
    int rainbowCol = tappedBlock.col;

    // 定义周围8个方向的偏移量
    List<List<int>> directions = [
      [-1, -1], [-1, 0], [-1, 1], // 上方三个位置
      [0, -1], [0, 0], [0, 1], // 左右两个位置
      [1, -1], [1, 0], [1, 1], // 下方三个位置
    ];

    // 选择一个随机的星星颜色类型
    List<BlockType> starTypes = [
      BlockType.red_star,
      BlockType.blue_star,
      BlockType.green_star,
      BlockType.yellow_star,
      BlockType.purple_star,
    ];
    BlockType randomColorType =
        starTypes[DateTime.now().millisecondsSinceEpoch % starTypes.length];

    // 创建一个新的StarBlock替换彩虹方块
    StarBlock newStarBlock = StarBlock(
      row: rainbowRow,
      col: rainbowCol,
      blockType: randomColorType,
      iconSprite: sprites[randomColorType.value]!,
      size: Vector2.all(blockSize),
      scene: this,
    );
    newStarBlock.position = tappedBlock.position;

    // 替换彩虹方块
    remove(tappedBlock);
    add(newStarBlock);
    grid[rainbowRow][rainbowCol] = newStarBlock;

    // 遍历周围8个方向
    for (List<int> dir in directions) {
      int newRow = rainbowRow + dir[0];
      int newCol = rainbowCol + dir[1];

      // 检查位置是否在有效范围内
      if (newRow >= 0 &&
          newRow < grid.length &&
          newCol >= 0 &&
          newCol < grid[0].length &&
          grid[newRow][newCol] != null) {
        BaseBlock? neighborBlock = grid[newRow][newCol];
        // 检查是否为StarBlock类型
        if (neighborBlock is StarBlock) {
          // 使用动画切换到随机选择的颜色
          neighborBlock.switchColorTypeWithAnimation(randomColorType);
        }
      }
    }
    // 等待所有动画完成（约1秒，根据StarBlock中定义的8次闪烁计算）
    await Future.delayed(const Duration(milliseconds: 1500));

    isProcessingElimination = false;
    _dropBlocksAndThenShift(); //执行算法结算
  }

  /// 处理盲盒点击
  Future<void> _handleBoxTap(BaseBlock tappedBlock) async {
    // 消除随机出现盲盒： 拆开盲盒随机道具（锤子，刷新，改色笔）

    // 设置为正在处理消除状态
    isProcessingElimination = true;

    // 播放点击音效
    SoundPool().playSelect();

    // 移除盲盒方块
    remove(tappedBlock);
    grid[tappedBlock.row][tappedBlock.col] = null;

    // 计算屏幕中心位置
    final screenCenter = Vector2(game.size.x / 2, game.size.y / 2);

    // 创建盲盒开启动画
    final boxAnimation = BoxOpenAnimation(
      startPosition: tappedBlock.position + tappedBlock.size / 2,
      targetPosition: screenCenter,
      boxSprite: sprites[BlockType.box.value], // 使用加载的盲盒精灵
      onComplete: () {
        //执行方块坠落
        _dropBlocksAndThenShift();
      },
      onItemClaimed: (ItemType itemType) {
        Future.delayed(Duration(milliseconds: 100), () {
          if (itemType == ItemType.hammer) {
            hammerBtn.updateBadge();
          } else if (itemType == ItemType.refresh) {
            refreshButton.updateBadge();
          } else if (itemType == ItemType.pen) {
            penBtn.updateBadge();
          }
        });
        // 恢复游戏状态
        isProcessingElimination = false;
      },
    );

    // 添加动画到场景
    add(boxAnimation);
  }

  /// 火箭类型到目标星星类型的映射表
  static final _rocketTypeMap = <BlockType, BlockType>{
    BlockType.rocket_blue: BlockType.blue_star,
    BlockType.rocket_red: BlockType.red_star,
    BlockType.rocket_purple: BlockType.purple_star,
    BlockType.rocket_green: BlockType.green_star,
    BlockType.rocket_yellow: BlockType.yellow_star,
  };

  /// 处理所有火箭类型点击
  Future<void> _handleRocketTap(BaseBlock tappedBlock) async {
    // 设置为正在处理消除状态
    isProcessingElimination = true;
    // 标记为已消除
    hasMadeElimination = true;

    // 播放音效
    SoundPool().playPop();

    // 使用映射表快速查找目标星星类型（替代switch）
    final targetStarType =
        _rocketTypeMap[tappedBlock.blockType] ?? BlockType.blue_star;

    // 预计算发射位置
    final launcherCenter = tappedBlock.position;

    // 找到所有目标颜色的星星方块（优化：提前终止条件）
    final targetBlocks = <BaseBlock>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final block = grid[r][c];
        if (block != null && block.blockType == targetStarType) {
          targetBlocks.add(block);
        }
      }
    }

    if (targetBlocks.isEmpty) {
      // 如果没有目标方块，执行下落和移动
      _dropBlocksAndThenShift();
      // 恢复用户点击
      isProcessingElimination = false;
      return;
    }

    // 预计算分数目标位置
    final scoreTarget =
        scoreText.absoluteCenter + Vector2(0, scoreText.size.y / 2);

    // 按距离排序目标方块，近的先发射，远的后发射
    // 优化：预计算距离并缓存，避免排序过程中重复计算
    final List<(BaseBlock, double)> blocksWithDistance = [];
    for (final block in targetBlocks) {
      final center = block.position + block.size / 2;
      final distanceSq = (center - launcherCenter).length2;
      blocksWithDistance.add((block, distanceSq));
    }

    // 按预计算的距离排序
    blocksWithDistance.sort((a, b) => a.$2.compareTo(b.$2));

    // 提取排序后的方块
    targetBlocks
      ..clear()
      ..addAll(blocksWithDistance.map((e) => e.$1));

    // 预计算音效播放间隔，减少重复调用
    final totalBlocks = targetBlocks.length;
    int completedCount = 0;

    // 优化：限制同时运行的火箭动画数量，避免卡顿
    const maxConcurrentRockets = 5;
    int activeRockets = 0;

    for (int i = 0; i < totalBlocks; i++) {
      final targetBlock = targetBlocks[i];
      final targetCenter = targetBlock.position + targetBlock.size / 2;
      final score = 5 + i * 10;

      // 等待并发火箭数量下降到限制以下
      while (activeRockets >= maxConcurrentRockets) {
        await Future.delayed(const Duration(milliseconds: 30));
      }

      activeRockets++;

      // 只在第一个和间隔播放音效，避免音效过于密集
      if (i == 0 || i % 4 == 0) {
        SoundPool().playRocketwhoosh();
      }

      add(
        RocketArcWithTrail(
          start: launcherCenter,
          end: targetCenter,
          rocketType: tappedBlock.blockType,
          rocketSprite: sprites[tappedBlock.blockType.value],
          onComplete: () {
            SoundPool().playPop();

            // 爆炸粒子（优化：根据距离调整粒子数量）
            add(
              StarExplosionComponent(
                position: targetCenter,
                totalCount: 20, // 减少粒子数量
              ),
            );

            // 添加分数字飘效果（优化：限制同时飘字数量）
            if (completedCount < 5 || completedCount % 2 == 0) {
              add(
                FloatingScoreComponent(
                  start: targetCenter,
                  end: scoreTarget,
                  score: score,
                  onArrived: () {
                    SoundPool().playScore();
                    gameDataManager.setScore(
                      gameDataManager.getScore() + score,
                    );
                    _updateScoreText();
                  },
                  delay: 0.3, // 缩短延迟
                ),
              );
            } else {
              // 对于超出限制的方块，直接加分不显示飘字
              gameDataManager.setScore(gameDataManager.getScore() + score);
              _updateScoreText();
            }

            // 立即移除目标星星
            remove(targetBlock);
            grid[targetBlock.row][targetBlock.col] = null;

            activeRockets--;
            completedCount++;

            // 检查是否所有动画都已完成
            if (completedCount == totalBlocks) {
              // 移除火箭方块
              remove(tappedBlock);
              grid[tappedBlock.row][tappedBlock.col] = null;
              _scheduleDropAndShift();
            }
          },
        ),
      );

      // 添加发射延迟（依次发射），优化延迟策略
      if (i < totalBlocks - 1) {
        await Future.delayed(Duration(milliseconds: (i < 3 ? i * 25 : 50)));
      }
    }
  }

  /// 调度下落和移动操作
  void _scheduleDropAndShift() {
    // 使用微延迟确保动画完成
    Future.delayed(const Duration(milliseconds: 300), () {
      _dropBlocksAndThenShift();
      isProcessingElimination = false;
    });
  }

  /// 执行消除操作
  Future<void> _executeElimination(BaseBlock tappedBlock) async {
    // 如果点击的就是当前选中的，执行消除
    if (currentlyHighlighted.length < 2) {
      // 少于两个，取消高亮
      for (final key in currentlyHighlighted) {
        final parts = key.split(',');
        final r = int.parse(parts[0]);
        final c = int.parse(parts[1]);
        grid[r][c]?.setHighlight(false);
      }
      currentlyHighlighted.clear();
      return;
    }
    // 执行消除操作，标记为已消除
    hasMadeElimination = true;

    _currentlyHighlightedScoreFlying(); // 分数动画

    //combo
    comboManager.onClear(clearCount: 2, currentTime: gameRef.currentTime());
    // 添加爆炸效果并移除
    for (final key in currentlyHighlighted) {
      final parts = key.split(',');
      final r = int.parse(parts[0]);
      final c = int.parse(parts[1]);
      final block = grid[r][c];

      if (block != null) {
        // 添加爆炸粒子效果
        add(
          StarExplosionComponent(
            position: block.position + block.size / 2,
            totalCount: 50,
          ),
        );

        SoundPool().playPop();
        // 删除星星
        remove(block);
        grid[r][c] = null;
      }

      // 每个星星间隔 100ms
      await Future.delayed(const Duration(milliseconds: 100));
    }

    //创建特殊方块
    _handleCreateSpecialBlock(tappedBlock: tappedBlock);

    if (lightningBlock != null) {
      //如果存在闪电，设置闪电的目标数量和目标类型
      lightningBlock!.setTargetCountAndType(
        count: currentlyHighlighted.length,
        type: tappedBlock.blockType,
      );
    }

    //消除情趣价值效果
    showPraise(currentlyHighlighted.length); //弹出上升赞美图标
    currentlyHighlighted.clear();
    _dropBlocksAndThenShift();
  }

  /// 高亮方块
  void _highlightBlocks(Set<String> blocks) {
    for (final key in blocks) {
      final parts = key.split(',');
      final r = int.parse(parts[0]);
      final c = int.parse(parts[1]);
      grid[r][c]?.setHighlight(true);
    }
    currentlyHighlighted = blocks;
    SoundPool().playSelect();
  }

  /// 切换高亮
  void _switchHighlight(Set<String> newBlocks) {
    for (final key in currentlyHighlighted) {
      final parts = key.split(',');
      final r = int.parse(parts[0]);
      final c = int.parse(parts[1]);
      grid[r][c]?.setHighlight(false);
    }
    for (final key in newBlocks) {
      final parts = key.split(',');
      final r = int.parse(parts[0]);
      final c = int.parse(parts[1]);
      grid[r][c]?.setHighlight(true);
    }
    currentlyHighlighted = newBlocks;
  }

  /// 分数字飘向 Score
  void _currentlyHighlightedScoreFlying() {
    int i = 0;
    for (final key in currentlyHighlighted) {
      final index = i;
      final parts = key.split(',');
      final r = int.parse(parts[0]);
      final c = int.parse(parts[1]);
      final block = grid[r][c];
      if (block != null) {
        cleanBlockScoreFly(block: block, index: i);
        i++;
      }
    }
  }

  // 随机选择一个星星方块
  BaseBlock? _selectRandomStar() {
    // 收集所有非空方块
    final List<BaseBlock> availableBlocks = [];
    for (var row in grid) {
      for (var block in row) {
        if (block != null &&
            (block.blockType.name.contains(BlockType.green_star.value) ||
                block.blockType.name.contains(BlockType.blue_star.value) ||
                block.blockType.name.contains(BlockType.red_star.value) ||
                block.blockType.name.contains(BlockType.yellow_star.value) ||
                block.blockType.name.contains(BlockType.purple_star.value))) {
          availableBlocks.add(block);
        }
      }
    }

    if (availableBlocks.isEmpty) {
      return null;
    }

    final random = Random();
    return availableBlocks[random.nextInt(availableBlocks.length)];
  }

  // 随机选择一个方块（用于锤子功能）
  BaseBlock? _selectRandomBlock() {
    final List<BaseBlock> availableBlocks = [];

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final block = grid[r][c];
        if (block != null) {
          availableBlocks.add(block);
        }
      }
    }

    if (availableBlocks.isEmpty) return null;

    return availableBlocks[random.nextInt(availableBlocks.length)];
  }

  // 显示锤子动画
  Future<void> _showHammerAnimation(BaseBlock block) async {
    // 先删除旧的锤子动画
    _removeHammerAnimation();
    // 保存选中的方块
    _hammerSelectedBlock = block;
    hammerBtn.isSelected = true;

    // 添加或显示提示文字
    if (_hammerHintText == null) {
      _hammerHintText = TextComponent(
        text: 'Double-tap the star to break it!'.tr,
        position: Vector2(size.x - 55 - 55 - 55 - 60, safeAreaTop + 170),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(blurRadius: 5, color: Colors.teal, offset: Offset(2, 2)),
            ],
          ),
        ),
        anchor: Anchor.center,
      );
      add(_hammerHintText!);
    } else {
      // 如果已经存在（但可能被移除），重新添加并淡入
      if (!_hammerHintText!.isMounted) {
        add(_hammerHintText!);
      }
    }

    // 加载锤子图片
    final hammerSprite = await gameRef.loadSprite('btn/chuizi.png');

    // 创建锤子动画组件 - 使用底部中心点作为锚点（锤柄支点）
    _hammerAnimationComponent = SpriteComponent(
      sprite: hammerSprite,
      size: Vector2(60, 60),
      position: block.position + Vector2(25, 0), // 调整位置，使支点位于合适位置
      anchor: Anchor.bottomCenter, // 以底部中心为支点
    );

    add(_hammerAnimationComponent!);

    // 开始锤击动画
    _startHammerHitAnimation();

    // 开始方块的脉冲动画，提示用户可以点击
    block.startPulseAnimation();
    // block.setAnimationParameters(speed: 1.5, amplitude: 0.15);
  }

  // 开始锤击动画 - 以锤柄为支点的弧度锤打
  void _startHammerHitAnimation() {
    if (_hammerAnimationComponent == null) return;

    // 创建旋转锤击的动画
    // 先向后抬起一点
    _hammerAnimationComponent!.add(
      SequenceEffect([
        // 先向后抬起（逆时针旋转）
        RotateEffect.to(
          -0.3, // 弧度，约-11.5度
          EffectController(duration: 0.5),
        ),
        // 然后向前锤下（顺时针旋转）
        RotateEffect.to(
          0.3, // 弧度，约23度
          EffectController(duration: 0.5),
        ),
        // // 回退一点
        // RotateEffect.to(
        //   0.1, // 弧度，约5.7度
        //   EffectController(duration: 0.15),
        // ),
        // // 再次锤下
        // RotateEffect.to(
        //   0.4, // 弧度，约23度
        //   EffectController(duration: 0.15),
        // ),
        // 回到初始位置
        RotateEffect.to(0.0, EffectController(duration: 0.2)),
      ], infinite: true),
    );
  }

  // 移除锤子动画
  void _removeHammerAnimation() {
    hammerBtn.isSelected = false;
    if (_hammerAnimationComponent != null) {
      remove(_hammerAnimationComponent!);
      _hammerAnimationComponent = null;
    }

    if (_hammerSelectedBlock != null) {
      _hammerSelectedBlock!.stopPulseAnimation();
      _hammerSelectedBlock = null;
    }

    // 淡出 + 移除提示文字
    if (_hammerHintText != null) {
      remove(_hammerHintText!);
      _hammerHintText = null;
    }
  }

  // 处理锤子点击消除方块
  Future<void> _handleHammerTap(BaseBlock tappedBlock) async {
    // 设置为正在处理消除状态
    isProcessingElimination = true;
    // 标记为已消除
    hasMadeElimination = true;
    // 播放销毁音效
    SoundPool().playPop();

    // 添加分数飞行动画
    add(
      FloatingScoreComponent(
        start: tappedBlock.position,
        end: scoreText.absoluteCenter + Vector2(0, scoreText.size.y / 2),
        score: 10,
        onArrived: () {
          SoundPool().playScore(); // 播放加分音效
          gameDataManager.setScore(gameDataManager.getScore() + 10);
          _updateScoreText();
        },
        delay: 0.2,
      ),
    );

    // 添加爆炸粒子效果
    add(StarExplosionComponent(position: tappedBlock.position, totalCount: 50));
    // 删除方块
    remove(tappedBlock);
    grid[tappedBlock.row][tappedBlock.col] = null;

    // 清除锤子动画和选中状态
    _removeHammerAnimation();

    // 延迟一点时间让爆炸效果显示
    await Future.delayed(const Duration(milliseconds: 100));

    // 执行方块下落和移动
    _dropBlocksAndThenShift();

    //消耗一次
    gameDataManager.reduceHammerCount();
    hammerBtn.updateBadge();
    // 重置处理状态
    isProcessingElimination = false;
  }

  // 移除颜色窗口
  void _removeColorSelectionWindow() {
    penBtn.isSelected = false;
    if (_currentColorWindow != null) {
      _currentColorWindow!.removeFromParent();
      _currentColorWindow = null;
    }
    // 淡出 + 移除提示文字
    if (_colorSelectionHintText != null) {
      remove(_colorSelectionHintText!);
      _colorSelectionHintText = null;
    }
  }

  // 显示颜色选择窗口
  void _showColorSelectionWindow(BaseBlock targetBlock) {
    penBtn.isSelected = true;
    clearCurrentlyHilightted(); //清空旧的高亮
    insertCurrentlyHighlighted(r: targetBlock.row, c: targetBlock.col); //添加选中高亮
    // 添加或显示提示文字
    if (_colorSelectionHintText == null) {
      _colorSelectionHintText = TextComponent(
        text: 'Tap a star to change its color!'.tr,
        position: Vector2(size.x - 55 - 55 - 55 - 60, safeAreaTop + 170),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 3,
                color: Colors.teal,
                offset: Offset(1.5, 1.5),
              ),
            ],
          ),
        ),
        anchor: Anchor.center,
      );
      add(_colorSelectionHintText!);
    } else {
      // 如果已经存在（但可能被移除），重新添加并淡入
      if (!_colorSelectionHintText!.isMounted) {
        add(_colorSelectionHintText!);
      }
    }

    // 更新或创建颜色选择窗口
    if (_currentColorWindow != null) {
      _currentColorWindow!.updateTargetBlock(targetBlock);
    } else {
      final colorWindow = PenBlockSelectWindow(
        targetBlock: targetBlock,
        scene: this,
        gameWidth: gameRef.size.x,
        gameHeight: gameRef.size.y,
        onColorSelected: (newColorType) {
          _changeBlockColor(_currentColorWindow!.targetBlock, newColorType);
          penBtn.isSelected = false;

          gameDataManager.reducePenCount(); //消耗一次
          penBtn.updateBadge(); //更新按钮数量
          _removeColorSelectionWindow();
          clearCurrentlyHilightted(); //清空当前高亮
        },
        onClose: () {
          _removeColorSelectionWindow();
          clearCurrentlyHilightted(); //清空当前高亮
        },
      );
      add(colorWindow);
      _currentColorWindow = colorWindow;
    }
  }

  // 改变方块颜色
  void _changeBlockColor(BaseBlock block, BlockType newColorType) {
    // 更新方块类型
    // (block as StarBlock).blockType = newColorType;
    // block.sprite = sprites[newColorType.value];

    // 更新方块精灵&类型
    (block as StarBlock).updateTypeAndIcon(
      newType: newColorType,
      newIcon: sprites[newColorType.value],
    );

    // 标记游戏已进行操作
    hasMadeElimination = true;

    // 保存游戏状态
    saveGameState();
  }

  // 应用生命周期监听
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // 应用进入后台、失去焦点或分离时停止背景音乐
        SoundPool().pauseBackground();
        break;
      case AppLifecycleState.resumed:
        // 应用恢复前台时重新播放背景音乐（如果需要）
        SoundPool().resumeBackground();
        break;
      case AppLifecycleState.hidden:
        // 应用隐藏时停止背景音乐
        SoundPool().stopBackground();
        break;
    }
  }
}

// 用于存储目标方块信息的辅助类
class _TargetBlockInfo {
  final BaseBlock block;
  final int distance;

  _TargetBlockInfo({required this.block, required this.distance});
}
