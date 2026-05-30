import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:wxx_cubia/util/huuua_icon_button.dart';
import 'package:wxx_cubia/util_flame/audio_controller.dart';

class SoundToggleButton extends StatefulWidget {
  const SoundToggleButton({super.key});

  @override
  State<SoundToggleButton> createState() => _SoundToggleButtonState();
}

class _SoundToggleButtonState extends State<SoundToggleButton> {
  bool isSoundOn = !AudioController.isMuted;

  @override
  void initState() {
    super.initState();
    // 监听声音状态变化
    // 这里可以添加一个监听器来实时更新状态
  }

  void handlePressed() async {
    if (isSoundOn) {
      await AudioController.mute();
    } else {
      await AudioController.unmute();
    }

    setState(() {
      isSoundOn = !isSoundOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HuuuaIconButton(
      chilWidget: Icon(
        isSoundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
        size: 30,
        color: Colors.white,
      ),
      text: "free_claim".tr,
      onTap: handlePressed,
    );
  }
}
