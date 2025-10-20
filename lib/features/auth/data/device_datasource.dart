import 'package:cloud_functions/cloud_functions.dart';
import 'package:ella_passenger/features/auth/data/models/device_snapshot.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeviceDataSource {
  late final FirebaseFunctions _functions;
  late final FirebaseAuth _auth;

  DeviceDataSource(this._functions, this._auth);

  Future<void> registerOrUpdate() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final snapshot = await DeviceSnapshot.capture();

    final result = await _functions.httpsCallable('registerDevice').call({
      'device': snapshot.toMap(),
    });

    print("function_result: ${result.data}");


  }
}
