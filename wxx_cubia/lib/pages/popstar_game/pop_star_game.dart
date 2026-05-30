import 'package:flame/game.dart';
import 'package:wxx_cubia/pages/popstar_game/home/home_scene.dart';
import 'package:wxx_cubia/pages/popstar_game/test/test_scene.dart';
import 'package:wxx_cubia/scene_manager_component.dart';
import 'package:wxx_cubia/util_flame/sound_pool.dart';

import 'game/component/game_background.dart';
import 'game/gameplay_scene.dart';

class PopStarGame extends FlameGame {
  late final SceneManagerComponent sceneManager;

  @override
  Future<void> onLoad() async {
    add(GameBackground());
    await SoundPool().init();
    sceneManager = SceneManagerComponent();
    add(sceneManager);

    // 注册首页
    sceneManager.registerScene(
      'menu',
      (args) => HomeScene(
        onStartPressed: (bool startNewGame) {
          SoundPool().playButton();
          sceneManager.switchTo('game', args: {'startNewGame': startNewGame});
        },
        onTestPressed: (bool startNewGame) {
          SoundPool().playButton();
          sceneManager.switchTo('test', args: {'startNewGame': startNewGame});
        },
      ),
    );

    // 注册游戏
    sceneManager.registerScene(
      'game',
      (args) => GameplayScene(
        onExitPressed: () {
          SoundPool().playButton();
          sceneManager.switchTo('menu');
        },
        startNewGame: args?['startNewGame'] ?? false,
      ),
    );

    // 注册游戏
    sceneManager.registerScene(
      'test',
      (args) => TestScene(
        onStartPressed: (bool startNewGame) {
          SoundPool().playButton();
          sceneManager.switchTo('menu');
        },
      ),
    );

    await sceneManager.switchTo('menu');
  }
}
