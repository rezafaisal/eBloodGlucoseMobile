import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../service/utils_service.dart';

class NewsPageController extends GetxController {
  final UtilService utilService = UtilService();
  final listData = [].obs;
  final token = ''.obs;

  @override
  void onInit() {
    newsPost();
    super.onInit();
  }

  newsPost() async {
    if (Hive.isBoxOpen('token')) {
      var box = await Hive.openBox('token');
      token.value = box.getAt(0);
    }
    final connect = GetConnect();
    await connect.get(
        '${utilService.url}/api/article',
        headers: {
          'Authorization': 'Bearer $token'
        }
    ).then((response) async {
      if(response.statusCode == 200) {
        listData.value = response.body['article']['data'];
      }
    });
  }
}
