import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:wxx_cubia/util/huuua_icon_button.dart';
import 'package:wxx_cubia/util_flame/audio_controller.dart';

class BgmToggleButton extends StatefulWidget {
  const BgmToggleButton({super.key});

  @override
  State<BgmToggleButton> createState() => _SoundToggleButtonState();
}

class _SoundToggleButtonState extends State<BgmToggleButton> {
  bool isBGM = !AudioController.isBGM;

  @override
  void initState() {
    super.initState();
    // 监听声音状态变化
    // 这里可以添加一个监听器来实时更新状态
  }

  void handlePressed() async {
    if (isBGM) {
      await AudioController.openBgm();
    } else {
      await AudioController.closeBgm();
    }

    setState(() {
      isBGM = !isBGM;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HuuuaIconButton(
      chilWidget: Icon(
        isBGM ? Icons.volume_off_rounded : Icons.volume_up_rounded,
        size: 30,
        color: Colors.white,
      ),
      text: "free_claim".tr,
      onTap: handlePressed,
    );
  }
}
