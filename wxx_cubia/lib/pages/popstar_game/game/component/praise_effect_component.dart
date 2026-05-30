import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';

// 赞美图标浮动效果
class PraiseEffectComponent extends SpriteComponent with HasGameRef<FlameGame> {
  final String imagePath;

  static final Map<String, Sprite> _spriteCache = {};

  PraiseEffectComponent({
    required this.imagePath,
    required Vector2 position,
    double size = 150,
  }) : super(
         position: position,
         size: Vector2.all(size),
         anchor: Anchor.center,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await _loadSprite(imagePath);

    add(MoveEffect.by(Vector2(0, -50), EffectController(duration: 0.5)));

    add(
      OpacityEffect.to(
        0,
        EffectController(duration: 0.8, startDelay: 0.3),
        onComplete: () {
          removeFromParent();
        },
      ),
    );
  }

  /// 加载并缓存 sprite
  static Future<Sprite> _loadSprite(String path) async {
    if (_spriteCache.containsKey(path)) {
      return _spriteCache[path]!;
    } else {
      final sprite = await Sprite.load(path);
      _spriteCache[path] = sprite;
      return sprite;
    }
  }
}
