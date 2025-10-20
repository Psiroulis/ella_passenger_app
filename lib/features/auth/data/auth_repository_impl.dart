import 'package:ella_passenger/features/auth/domain/auth_repository.dart';

import 'firebase_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource _authDataSource;

  AuthRepositoryImpl(this._authDataSource);

  @override
  Future<void> startPhoneSignIn({required String phone}) {
    throw UnimplementedError(
      'Use Notifier wrapper with callbacks for codeSent/failed',
    );
  }

  @override
  Future<void> verifySmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    await _authDataSource.verifySmsCode(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  @override
  Future<String?> currentUserId() async => _authDataSource.currentUserId();

  @override
  Future<void> signOut() => _authDataSource.signOut();

  @override
  Stream<String?> watchUserId() => _authDataSource.watchUserId();
}
