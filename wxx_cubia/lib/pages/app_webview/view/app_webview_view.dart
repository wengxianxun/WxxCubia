import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:wxx_cubia/pages/app_webview/app_webview_controller.dart';

class AppWebviewView extends GetView<AppWebviewController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(Icons.arrow_back),
          color: Colors.black87,
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.transparent,
        centerTitle: false,
        elevation: 0.0,
        titleSpacing: 0.0,
        // shadowColor: Colors.transparent,
        title: Obx(() {
          return Text(
            controller.title.value,
            style: TextStyle(fontSize: 20, color: Colors.black87),
          );
        }),
      ),
      body: Obx(() {
        return webViewContent();
      }),
    );
  }

  Widget webViewContent() {
    // String pageview = controller.page.value == "1" ? getFWXY() : getYSZC();
    if (controller.url.value == null) {
      return Container();
    }
    return WebViewWidget(controller: controller.webViewController);
  }

  String getYSZC() {
    return r"""
      

    """;
  }

  String getFWXY() {
    return r""" 
    
    """;
  }
}
