import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_eco_mode/flutter_eco_mode_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterEcoModePlatform with MockPlatformInterfaceMixin  {

  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterEcoModePlatform initialPlatform = FlutterEcoModePlatform.instance;

}
