import 'package:flame_audio/flame_audio.dart';
import 'package:wxx_cubia/util_flame/audio_controller.dart';

class SoundPool {
  static final SoundPool _instance = SoundPool._internal();
  factory SoundPool() => _instance;
  SoundPool._internal();

  late AudioPool popPool;
  late AudioPool scorePool;
  late AudioPool buttonPool;
  late AudioPool nextLevelPool;
  late AudioPool gameOverPool;
  late AudioPool startgamePool;
  late AudioPool newBlockPopPool;
  late AudioPool selectPool;
  late AudioPool completePool;
  late AudioPool excellentPool;
  late AudioPool perfectPool;
  late AudioPool greatPool;
  late AudioPool nicePool;
  late AudioPool goodPool;
  late AudioPool dingdongPool;
  late AudioPool bubblePool;
  late AudioPool droppopPool;
  late AudioPool laserPool;
  late AudioPool lightningPool;
  late AudioPool rocketwhooshPool;
  late AudioPool rainbowPool;
  late AudioPool comboPool;

  Future<void> init() async {
    popPool = await FlameAudio.createPool('destroyStar.mp3', maxPlayers: 10);
    newBlockPopPool = await FlameAudio.createPool(
      'new_block_pop.wav',
      maxPlayers: 2,
    );
    scorePool = await FlameAudio.createPool('score2.wav', maxPlayers: 5);
    buttonPool = await FlameAudio.createPool('button2.wav', maxPlayers: 5);
    bubblePool = await FlameAudio.createPool('bubble.wav', maxPlayers: 5);
    nextLevelPool = await FlameAudio.createPool('nextlevel.wav', maxPlayers: 2);
    startgamePool = await FlameAudio.createPool(
      'background1.mp3',
      maxPlayers: 1,
    );
    gameOverPool = await FlameAudio.createPool('gameover.wav', maxPlayers: 2);

    selectPool = await FlameAudio.createPool('select.mp3', maxPlayers: 5);
    completePool = await FlameAudio.createPool('complete.wav', maxPlayers: 2);
    excellentPool = await FlameAudio.createPool('excellent.mp3', maxPlayers: 2);
    perfectPool = await FlameAudio.createPool('perfect.mp3', maxPlayers: 2);
    greatPool = await FlameAudio.createPool('great.mp3', maxPlayers: 2);
    nicePool = await FlameAudio.createPool('nice.mp3', maxPlayers: 2);
    goodPool = await FlameAudio.createPool('good.mp3', maxPlayers: 2);
    dingdongPool = await FlameAudio.createPool('dingdong.wav', maxPlayers: 2);
    droppopPool = await FlameAudio.createPool('droppop.mp3', maxPlayers: 2);
    laserPool = await FlameAudio.createPool('laser.wav', maxPlayers: 2);
    lightningPool = await FlameAudio.createPool('lightning.mp3', maxPlayers: 2);
    rocketwhooshPool = await FlameAudio.createPool(
      'rocketwhoosh.wav',
      maxPlayers: 2,
    );
    rainbowPool = await FlameAudio.createPool('rainbow.wav', maxPlayers: 2);
    comboPool = await FlameAudio.createPool('combo.wav', maxPlayers: 2);
  }

  void playPraise(String name) {
    if (!AudioController.isMuted) {
      switch (name) {
        case 'excellent.mp3':
          excellentPool.start();
          break;
        case 'perfect.mp3':
          perfectPool.start();
          break;
        case 'great.mp3':
          greatPool.start();
          break;
        case 'nice.mp3':
          nicePool.start();
          break;
        case 'good.mp3':
          goodPool.start();
          break;
      }
    }
  }

  AudioPlayer? _bgmPlayer;

  Future<void> playBackground() async {
    if (AudioController.isBGM) {
      _bgmPlayer = await FlameAudio.playLongAudio("background2.mp3");
    }
  }

  void resumeBackground() {
    _bgmPlayer?.resume();
  }

  void pauseBackground() {
    _bgmPlayer?.pause();
  }

  void stopBackground() {
    _bgmPlayer?.stop();
  }

  // 彩虹
  void playRainbow() {
    if (!AudioController.isMuted) rainbowPool.start();
  }

  void playCombo() {
    if (!AudioController.isMuted) comboPool.start();
  }

  // 坠落弹跳
  void playDroppopPop() {
    if (!AudioController.isMuted) droppopPool.start();
  }

  // 激光
  void playLaser() {
    if (!AudioController.isMuted) laserPool.start();
  }

  // 火箭发射
  void playRocketwhoosh() {
    if (!AudioController.isMuted) rocketwhooshPool.start();
  }

  // 闪电
  void playLightning() {
    if (!AudioController.isMuted) lightningPool.start();
  }

  // 星星销毁爆炸音效
  void playPop() {
    if (!AudioController.isMuted) popPool.start();
  }

  void playBubble() {
    if (!AudioController.isMuted) bubblePool.start();
  }

  //出现新方块音效
  void playNewBlockPopPool() {
    if (!AudioController.isMuted) newBlockPopPool.start();
  }

  void playButton() {
    if (!AudioController.isMuted) buttonPool.start();
  }

  void playScore() {
    if (!AudioController.isMuted) scorePool.start();
  }

  void playNextLevel() {
    if (!AudioController.isMuted) nextLevelPool.start();
  }

  void playGameOver() {
    if (!AudioController.isMuted) gameOverPool.start();
  }

  void playSelect() {
    if (!AudioController.isMuted) selectPool.start();
  }

  void playComplete() {
    if (!AudioController.isMuted) completePool.start();
  }

  void playDingdong() {
    if (!AudioController.isMuted) dingdongPool.start();
  }

  void playStartGame() {
    if (!AudioController.isMuted) startgamePool.start(volume: 0.1);
  }

  // 播放获得道具音效
  void playGetItem() {}
}
