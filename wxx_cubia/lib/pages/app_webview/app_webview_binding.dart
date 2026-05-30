import 'package:get/get.dart';
import 'package:wxx_cubia/pages/app_webview/app_webview_controller.dart';

class AppWebviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AppWebviewController());
  }
}
