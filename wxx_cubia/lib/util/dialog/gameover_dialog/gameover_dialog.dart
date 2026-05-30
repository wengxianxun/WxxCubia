import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wxx_cubia/util/h_text_button.dart';
import 'package:wxx_cubia/util/huuua_dialog.dart';

// 改为StatefulWidget，确保UI能正确更新
class GameoverDialog extends StatefulWidget {
  const GameoverDialog({
    super.key,
    required this.onRestart,
    required this.onRevive,
  });

  final VoidCallback onRestart;
  final VoidCallback onRevive;

  /// ✅ 静态方法，直接调用即可
  static void show({
    required VoidCallback onRestart,
    required VoidCallback onRevive,
  }) {
    HuuuaDialog.show(
      childWidget: GameoverDialog(onRestart: onRestart, onRevive: onRevive),
      title: 'Tips'.tr,
      cancelTitle: 'close'.tr, // 使用国际化翻译
      onCancel: () {},
      showClose: false,
    );
  }

  @override
  State<GameoverDialog> createState() => _SettingDialogState();
}

class _SettingDialogState extends State<GameoverDialog> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // 1.激励广告奖励 2.免费领取 3.购买
    return Container(
      height: 200,
      child: Column(
        children: [
          Spacer(),
          _buildGameOverTitle(),
          Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              CustomButton(
                text: 'New Game'.tr,
                onTap: () {
                  HuuuaDialog.hide();
                  widget.onRestart();
                },
                width: 120,
                height: 45,
                fontSizeRatio: 0.45,
                hilightOrgRatio: 0.06,
                borderInnerGlowColor: Color(0xFFFFD54F),
              ),
              CustomButton(
                text: 'Revive'.tr,
                onTap: () {
                  HuuuaDialog.hide();
                  widget.onRevive();
                },
                width: 120,
                height: 45,
                fontSizeRatio: 0.45,
                hilightOrgRatio: 0.06,
                borderInnerGlowColor: Color(0xFFFFD54F),
              ),
            ],
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Game Over 标题（描边效果）
  Widget _buildGameOverTitle() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 描边层
        Text(
          'GAME OVER'.tr,
          style: TextStyle(
            fontSize: 50,
            fontWeight: FontWeight.w900,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = Colors.white,
          ),
        ),
        // 填充层
        Text(
          'GAME OVER'.tr,
          style: TextStyle(
            fontSize: 50,
            fontWeight: FontWeight.w900,
            color: Color(0xFFFF3366),
            shadows: [
              Shadow(
                offset: Offset(2, 2),
                blurRadius: 6,
                color: Colors.black38,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // 清理广告资源
    // _adManager.dispose();
    // _cancelCountdownTimer(); // 使用新的取消方法
    super.dispose();
  }
}
