import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:wxx_cubia/pages/app/app_controller.dart';
import 'package:wxx_cubia/routes/app_pages.dart';
import 'package:wxx_cubia/util/huuua_button.dart';
import 'package:wxx_cubia/util/huuua_config.dart';

class AppLunchView extends StatefulWidget {
  final VoidCallback onOpenCallBack;
  final AppController appController;

  AppLunchView({
    Key? key,
    required this.onOpenCallBack,
    required this.appController,
  }) : super(key: key);

  @override
  _LunchState createState() => _LunchState();
}

class _LunchState extends State<AppLunchView> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    if (HuuuaConfig.instance.flavorstype == flavors_type.taptap) {
      _checkSecret();
    }
  }

  // lunchbackground.png
  @override
  Widget build(BuildContext context) {
    final imgPath = HuuuaConfig.instance.getImagePath();

    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          // Positioned(
          //     child: Image.asset(
          //   "assets/images/lunchbackground.png",
          //   width: 375.w,
          //   height: 812.h,
          // )),
          Positioned(
            child: Container(
              width: 375.w,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 60.0.h + Get.context!.mediaQueryPadding.bottom!,
                  ),
                  Spacer(),
                  ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(22.r)),
                    child: Image.asset(
                      "assets/images/star/logo.png",
                      width: 109.w,
                      height: 109.w,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "POP STAR",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Spacer(),
                  (widget.appController.netType.value == NetType.noNet &&
                          !widget.appController.isNetloading.value)
                      ? Text(
                          "Network connection failed！\n Please check your network setings."
                              .tr,
                          softWrap: true,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: Colors.white,
                          ),
                        )
                      : Container(
                          child: LoadingAnimationWidget.threeArchedCircle(
                            color: Colors.white70,
                            size: 40,
                          ),
                        ),
                  SizedBox(
                    height: widget.appController.netType.value == NetType.noNet
                        ? 16
                        : 0,
                  ),
                  (widget.appController.netType.value == NetType.noNet &&
                          !widget.appController.isNetloading.value)
                      ? SizedBox(
                          width: 150,
                          height: 50,
                          child: HuuuaButton(
                            icon: Icon(
                              Icons.network_check,
                              size: 25,
                              color: Colors.white,
                            ),
                            text: "Retry".tr,
                            backgroundColor: Colors.blueAccent,
                            onTap: () {
                              widget.appController.checkNet();
                            },
                          ),
                        )
                      // HuuuaButton(
                      //         title: "Retry".tr,
                      //         fontSize: 16.sp,
                      //         borderWidth: 1,
                      //         width: 80.w,
                      //         height: 36.h,
                      //         // borderColor: GetTheme(HuuuaColorEnum.color_FFFFFF),
                      //         color: Colors.red,
                      //         textColor: Colors.yellow,
                      //         onTap: () async {
                      //           widget.appController.checkNet();
                      //         },
                      //       )
                      : Container(height: 50),
                  Spacer(),
                  Text(
                    "HUUUA.COM",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(
                    height: 60.0.h + Get.context!.mediaQueryPadding.bottom!,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _checkSecret() {
    Timer(Duration(seconds: 2), () async {
      if (HuuuaConfig.instance.agreeService) {
        widget.onOpenCallBack();
      } else {
        //初始化时 弹出弹出框 必须加上Future.delayed
        Future.delayed(Duration.zero, () {
          var textStyle = TextStyle(color: Colors.black, fontSize: 14);
          _showCupertinoAlertDialog(
            context: context,
            title: "服务协议和隐私政策",
            content: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text:
                        "欢迎使用本APP！\n\n我们非常重视您的个人信息和隐私保护，为了更好的保障您的个人权益，在您使用本APP前，请您认真阅读",
                    style: textStyle,
                  ),
                  TextSpan(
                    text: "《服务协议》",
                    style: TextStyle(color: Colors.blue, fontSize: 14),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Get.toNamed(
                          Routes.AppWebviewView,
                          arguments: {
                            'page': '1',
                            'title': '服务协议',
                            'url':
                                'https://wengxianxun.github.io/html/blockservice.html',
                          },
                        );
                        // Navigator.pushNamed(context, APRouter.page_service);
                        // Navigator.of(context).push(
                        //   new MaterialPageRoute(
                        //     builder: (context) => new PolicyScreen(
                        //         title: "服务协议", policyText: service_agreement),
                        //   ),
                        // );
                      },
                  ),
                  TextSpan(text: "和", style: textStyle),
                  TextSpan(
                    text: "《隐私政策》",
                    style: TextStyle(color: Colors.blue, fontSize: 14),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Get.toNamed(
                          Routes.AppWebviewView,
                          arguments: {
                            'page': '2',
                            'url':
                                'https://wengxianxun.github.io/html/blockprivate.html',
                            'title': '隐私政策',
                          },
                        );
                        // Navigator.pushNamed(context, APRouter.page_secret);
                        // Navigator.of(context).push(new MaterialPageRoute(
                        //     builder: (context) => new PolicyScreen(
                        //         title: "隐私政策", policyText: privacy_policy)));
                      },
                  ),
                  TextSpan(
                    text:
                        "的全部内容，同意并接受全部条款后开始使用我们的产品和服务。\n\n若选择不同意，将无法使用本APP，并会退出应用。",
                    style: textStyle,
                  ),
                ],
              ),
            ),
            sureText: "同意",
          );
        });
      }
    });
  }

  ///弹窗
  void _showCupertinoAlertDialog({
    context,
    required String title,
    required Widget content,
    required String sureText,
  }) {
    Get.defaultDialog(
      title: title,
      barrierDismissible: false,
      content: content,
      onConfirm: () async {
        Get.back();
        HuuuaConfig.instance.saveAgreeService(true);
        widget.appController.updateCheck();
        // showLoadingDialog();
        // Future.delayed(Duration(milliseconds: 500), () async {

        //   // await FlutterTencentad.register(
        //   //   androidId: TencentAdID,
        //   //   iosId: "iosId",
        //   //   debug: true,
        //   //   personalized: FlutterTencentadPersonalized.show, //是否显示个性化推荐广告
        //   //   channelId: FlutterTencentadChannel.other, //渠道id
        //   // );
        widget.onOpenCallBack();
        //   hideLoadingDialog();
        // });
      },
      onCancel: () {
        exit(0);
      },
      textConfirm: "同意",
      textCancel: "不同意并退出",
    );
  }
}
