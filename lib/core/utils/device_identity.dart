import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdentity {
  static const _key = 'kitchen_sync_device_id';
  Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null) return existing;
    final id = const Uuid().v4();
    await prefs.setString(_key, id);
    return id;
  }

  Future<String> label() async {
    final info = await DeviceInfoPlugin().androidInfo;
    return '${info.manufacturer} ${info.model}';
  }
}
