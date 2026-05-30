import 'package:flame_audio/flame_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioController {
  static bool isMuted = false;
  static bool isBGM = false;

  static Future<void> loadMuteState() async {
    final prefs = await SharedPreferences.getInstance();
    isMuted = prefs.getBool('isMuted') ?? false;
  }

  static Future<void> mute() async {
    isMuted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMuted', true);
    // 可选：立即停止音效播放
    final player = AudioPlayer();
    player.setVolume(0.0);
  }

  static Future<void> unmute() async {
    isMuted = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMuted', false);
    // 可选：恢复播放
    final player = AudioPlayer();
    player.setVolume(1.0);
  }

  static Future<void> loadBGMState() async {
    final prefs = await SharedPreferences.getInstance();
    isBGM = prefs.getBool('bgm') ?? false;
  }

  static Future<void> openBgm() async {
    isBGM = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bgm', true);
  }

  static Future<void> closeBgm() async {
    isBGM = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bgm', false);
  }

  static void play(String file) {
    if (isMuted) {
      return;
    }
    FlameAudio.play(file, volume: isMuted ? 0.0 : 1.0);
  }
}
