import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wxx_cubia/util/huuua_button.dart';
import 'package:wxx_cubia/util/huuua_dialog.dart';

// 改为StatefulWidget，确保UI能正确更新
class ReviveSuccessDialog extends StatefulWidget {
  const ReviveSuccessDialog({super.key, required this.onRestart});
  final VoidCallback onRestart;

  /// ✅ 静态方法，直接调用即可
  static void show({
    required VoidCallback onRestart,
    required VoidCallback onCancel,
  }) {
    HuuuaDialog.show(
      childWidget: ReviveSuccessDialog(onRestart: onRestart),
      title: 'Tips'.tr,
      showClose: false,
    );
  }

  @override
  State<ReviveSuccessDialog> createState() => _RefreshGetDialogState();
}

class _RefreshGetDialogState extends State<ReviveSuccessDialog> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // 1.激励广告奖励 2.免费领取 3.购买
    return Container(
      constraints: BoxConstraints(
        maxHeight:
            Get.height -
            (Get.mediaQuery.padding.bottom + 77 + Get.mediaQuery.padding.top),
      ),
      child: RawScrollbar(
        thumbColor: Colors.blue, // 滑块颜色
        trackColor: Colors.grey[200], // 轨道颜色
        trackBorderColor: Colors.grey, // 轨道边框颜色
        thickness: 10,
        radius: Radius.circular(5),
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20),
              Icon(Icons.handshake_outlined, color: Colors.green, size: 40),
              Text(
                "Congrats, you're back in the game!".tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                  shadows: [
                    Shadow(
                      blurRadius: 2,
                      color: Colors.black38,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              confirmBtn(),
            ],
          ),
        ),
      ),
    );
  }

  Widget confirmBtn() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HuuuaButton(
            text: "CONTINUE".tr,
            backgroundColor: Colors.green,
            onTap: () {
              HuuuaDialog.hide();
              widget.onRestart();
            },
          ),
        ],
      ),
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
