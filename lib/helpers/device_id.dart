import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceId {
  static const _key = 'app_device_id';
  static final _storage = FlutterSecureStorage();

  static Future<String> getOrCreate() async {
    var existing = await _storage.read(key: _key);

    if (existing != null && existing.isNotEmpty) return existing;

    final id = const Uuid().v4();

    await _storage.write(key: _key, value: id);

    return id;
  }
}
