import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:wxx_cubia/util/huuua_button.dart';

class HuuuaDialog extends StatelessWidget {
  final String? title;
  final String? message;
  final Widget? childWidget;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final String? cancelTitle;
  final String? confirmTitle;
  final bool showClose;

  const HuuuaDialog({
    super.key,
    this.title,
    this.message,
    this.childWidget,
    this.cancelTitle,
    this.confirmTitle,
    this.onConfirm,
    this.onCancel,
    this.showClose = true,
  });

  /// ✅ 静态方法，直接调用即可
  static void show({
    String? title,
    String? message,
    String? cancelTitle,
    String? confirmTitle,
    Widget? childWidget,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool showClose = true,
  }) {
    SmartDialog.show(
      clickMaskDismiss: false, // 🚫 禁止点击遮罩关闭
      maskColor: Colors.black54,
      builder: (context) {
        return HuuuaDialog(
          title: title,
          message: message,
          childWidget: childWidget,
          cancelTitle: cancelTitle,
          confirmTitle: confirmTitle,
          onConfirm: onConfirm,
          onCancel: onCancel,
          showClose: showClose,
        );
      },
    );
  }

  static void hide() {
    SmartDialog.dismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          boxView(),
          SizedBox(height: 12),
          if (showClose) closeBtn(),
          SizedBox(height: Get.mediaQuery.padding.bottom + 20),
        ],
      ),
    );
  }

  Widget boxView() {
    return Container(
      width: Get.width - 40,
      constraints: BoxConstraints(minWidth: Get.width - 40),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage("assets/images/popback.png"),

          // ✅ 九宫格拉伸必须配合 fill
          fit: BoxFit.fill,

          // ✅ 中心拉伸区域（必须在图片内部）
          centerSlice: const Rect.fromLTWH(50, 50, 10, 10),

          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
        ),
      ),
      margin: EdgeInsets.only(
        top: Get.mediaQuery.padding.top,
        left: 16,
        right: 16,
      ),
      padding: EdgeInsets.only(top: 20, bottom: 15, left: 16, right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            // 标题
            Text(
              title ?? "",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                shadows: [
                  Shadow(
                    blurRadius: 1,
                    color: Colors.black54,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
            ),

          if (message != null)
            Container(
              constraints: const BoxConstraints(
                minHeight: 120, // ✅ 最低高度
              ),
              margin: EdgeInsets.only(bottom: 16),
              alignment: Alignment.center,

              child: Text(
                message ?? "",
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
            ),
          if (confirmTitle != null) confirmBtn(),
          SizedBox(height: 6),
          if (childWidget != null) childWidget ?? Container(),
        ],
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
            text: confirmTitle,
            backgroundColor: Colors.green,
            onTap: () {
              onConfirm?.call();
            },
          ),
        ],
      ),
    );
  }

  Widget closeBtn() {
    return SizedBox(
      width: 45,
      height: 45,
      child: HuuuaButton(
        text: "",
        icon: Icon(
          Icons.close_rounded,
          color: Colors.white,
          size: 30,
          weight: 9,
        ),
        padding: EdgeInsets.zero,
        backgroundColor: Colors.black,
        borderRadius: 45 / 2,
        border: Border.all(width: 2, color: Colors.white70),
        onTap: () {
          SmartDialog.dismiss();
          onCancel?.call();
        },
      ),
    );
  }
}
