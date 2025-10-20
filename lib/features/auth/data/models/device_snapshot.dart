import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../helpers/device_id.dart';

class DeviceSnapshot {
  final String deviceId;
  final String platform;
  final String model;
  final String osVersion;
  final String appVersion;
  final String? fcmToken;

  DeviceSnapshot({
    required this.deviceId,
    required this.platform,
    required this.model,
    required this.osVersion,
    required this.appVersion,
    required this.fcmToken,
  });

  static Future<DeviceSnapshot> capture() async {
    final deviceId = await DeviceId.getOrCreate();

    final di = DeviceInfoPlugin();
    String platform, model, osVersion;

    if (Platform.isAndroid) {
      final info = await di.androidInfo;
      platform = 'android';
      model = '${info.brand} ${info.model}';
      osVersion = 'Android ${info.version.release} (${info.version.sdkInt})';
    } else if (Platform.isIOS) {
      final info = await di.iosInfo;
      platform = 'ios';
      model = info.utsname.machine ?? 'iPhone';
      osVersion = 'iOS ${info.systemVersion}';
    } else {
      platform = Platform.operatingSystem;
      model = 'unknown';
      osVersion = Platform.operatingSystemVersion;
    }

    final pkg = await PackageInfo.fromPlatform();
    final token = await FirebaseMessaging.instance.getToken();

    return DeviceSnapshot(
      deviceId: deviceId,
      platform: platform,
      model: model,
      osVersion: osVersion,
      appVersion: pkg.version,
      fcmToken: token,
    );
  }

  Map<String, dynamic> toMap() => {
    'deviceId': deviceId,
    'platform': platform,
    'model': model,
    'osVersion': osVersion,
    'appVersion': appVersion,
    'fcmToken': fcmToken,
  };
}
