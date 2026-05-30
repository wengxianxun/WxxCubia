import 'package:flame/components.dart';

typedef SceneBuilder = Component Function();

class SceneManagerComponent extends Component {
   final Map<String, Function(dynamic args)> _sceneFactories = {};
  Component? _currentScene;
  String? _currentSceneKey;

  // void registerScene(String key, SceneBuilder builder) {
  //   _sceneMap[key] = builder;
  // }
  void registerScene(String name, Function(dynamic args) factory) {
    _sceneFactories[name] = factory;
  }

  Future<void> switchTo(String key, {dynamic args}) async {
    if (_currentSceneKey == key) return;

    if (_currentScene != null) {
      remove(_currentScene!);
      _currentScene = null;
    }

    final builder = _sceneFactories[key];
    if (builder == null) {
      throw Exception('Scene "$key" not registered');
    }

    // 创建新场景
    final factory = _sceneFactories[key];
    if (factory != null) {
      _currentScene = factory(args) as PositionComponent?;
      if (_currentScene != null) {
        await add(_currentScene!);
      }
    }
  }
  // Future<void> switchTo(String key) async {
  //   if (_currentScene != null) {
  //     _currentScene!.add(OpacityEffect.to(0, EffectController(duration: 0.3)));
  //     await Future.delayed(Duration(milliseconds: 300));
  //     remove(_currentScene!);
  //   }
  //
  //   final newScene = _sceneMap[key]!();
  //   // newScene.opacity = 0;
  //   _currentScene = newScene;
  //   _currentSceneKey = key;
  //   await add(newScene);
  //
  //   newScene.add(OpacityEffect.to(1, EffectController(duration: 0.3)));
  // }

  @override
  Future<void> onLoad() async {
    // 默认加载第一个注册场景（可选）
    if (_sceneFactories.isNotEmpty && _currentSceneKey == null) {
      final firstKey = _sceneFactories.keys.first;
      await switchTo(firstKey, args: null);
    }
  }

  // 添加获取当前场景的方法
  Component? getCurrentScene() {
    return _currentScene;
  }
}
