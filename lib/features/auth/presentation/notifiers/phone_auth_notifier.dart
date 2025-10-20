import 'package:ella_passenger/features/auth/data/device_datasource.dart';
import 'package:flutter/foundation.dart';

import '../../data/firebase_auth_datasource.dart';
import '../../data/user_profile_datasource.dart';

enum AuthStage { idle, sendingCode, codeSent, verifying, authed, error }

class PhoneAuthState {
  final AuthStage stage;
  final String? verificationId;
  final String? errorMessage;

  PhoneAuthState({
    this.stage = AuthStage.idle,
    this.verificationId,
    this.errorMessage,
  });

  PhoneAuthState copy({
    AuthStage? stage,
    String? verificationId,
    String? errorMessage,
  }) => PhoneAuthState(
    stage: stage ?? this.stage,
    verificationId: verificationId ?? this.verificationId,
    errorMessage: errorMessage,
  );
}

class PhoneAuthNotifier extends ChangeNotifier {
  final FirebaseAuthDataSource authDs;
  final UserProfileDataSource profileDs;
  final DeviceDataSource deviceDs;

  PhoneAuthState state = PhoneAuthState();

  PhoneAuthNotifier({required this.authDs, required this.profileDs, required this.deviceDs});

  Future<void> start({required String phoneE164}) async {
    state = state.copy(stage: AuthStage.sendingCode, errorMessage: null);
    notifyListeners();

    await authDs.startPhoneSignIn(
      phoneE164: phoneE164,
      onCodeSent: (verificationId, _) {
        state = state.copy(
          stage: AuthStage.codeSent,
          verificationId: verificationId,
        );
        notifyListeners();
      },
      onVerificationFailed: (e) {
        state = state.copy(stage: AuthStage.error, errorMessage: e.message);
        notifyListeners();
      },
    );
  }

  Future<void> verifyCode({
    required String smsCode,
    required String phoneE164,
    String? name,
  }) async {
    if (state.verificationId == null) return;
    state = state.copy(stage: AuthStage.verifying, errorMessage: null);
    notifyListeners();
    try {
      await authDs.verifySmsCode(
        verificationId: state.verificationId!,
        smsCode: smsCode,
      );

      final uid = await authDs.watchUserId().firstWhere((id) => id != null);
      if (uid != null) {
        await profileDs.loginToUserProfile(uid, phoneE164);
        await deviceDs.registerOrUpdate();
      }

      state = state.copy(stage: AuthStage.authed);
    } catch (e) {
      state = state.copy(stage: AuthStage.error, errorMessage: e.toString());
      print(e.toString());
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    await authDs.signOut();
    state = PhoneAuthState(stage: AuthStage.idle);
    notifyListeners();
  }
}
