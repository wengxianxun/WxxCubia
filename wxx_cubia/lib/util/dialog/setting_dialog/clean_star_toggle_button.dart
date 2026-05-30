import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:wxx_cubia/pages/popstar_game/game/manager/game_data_manager.dart';
import 'package:wxx_cubia/util/huuua_button.dart';

// 消除方式： 单机或者双击
class CleanStarToggleButton extends StatefulWidget {
  const CleanStarToggleButton({super.key});

  @override
  State<CleanStarToggleButton> createState() => _SoundToggleButtonState();
}

class _SoundToggleButtonState extends State<CleanStarToggleButton> {
  bool isDoubleTap = true;

  @override
  void initState() {
    super.initState();
    isDoubleTap = GameDataManager().doubleTap;
  }

  void handlePressed() async {
    GameDataManager().save_doubleTap(!isDoubleTap);
    setState(() {
      isDoubleTap = !isDoubleTap;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HuuuaButton(
      icon: Icon(Icons.touch_app_rounded, size: 22, color: Colors.white),
      text: isDoubleTap ? "双击".tr : "单击".tr,
      backgroundColor: isDoubleTap ? Colors.green : Colors.blue,
      onTap: () {
        handlePressed();
      },
    );
  }
}
