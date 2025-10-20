abstract class AuthRepository {
  Future<void> startPhoneSignIn({required String phone});
  Future<void> verifySmsCode({required String verificationId, required String smsCode});
  Future<void> signOut();
  Stream<String?> watchUserId();
  Future<String?> currentUserId();

}