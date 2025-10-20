import 'package:firebase_auth/firebase_auth.dart';

typedef CodeSent =
    void Function(String verificationId, int? forceResendingToken);
typedef VerificationFailed = void Function(FirebaseAuthException e);

class FirebaseAuthDataSource {
  late final FirebaseAuth _auth;

  FirebaseAuthDataSource(this._auth);

  Future<void> startPhoneSignIn({
    required String phoneE164,
    required CodeSent onCodeSent,
    required VerificationFailed onVerificationFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneE164,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        try {
          await _auth.signInWithCredential(credential);
        } catch (_) {}
      },
      verificationFailed: onVerificationFailed,
      codeSent: (verificationId, forceResendingToken) =>
          onCodeSent(verificationId, forceResendingToken),
      codeAutoRetrievalTimeout: (verificationId) {},
    );
  }

  Future<void> verifySmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _auth.signInWithCredential(credential);
  }

  Stream<String?> watchUserId() => _auth.authStateChanges().map((u) => u?.uid);

  Future<void> signOut() => _auth.signOut();

  String? currentUserId() => _auth.currentUser?.uid;
}
