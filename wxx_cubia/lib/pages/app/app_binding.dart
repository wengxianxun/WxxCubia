import 'package:get/get.dart';
import 'package:wxx_cubia/pages/app/app_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AppController());
  }
}
