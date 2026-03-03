import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── Phone Auth ────────────────────────────────────────────────────────────

  /// Step 1: Send OTP to [phoneNumber] (e.g. '+919876543210').
  /// Calls [onCodeSent] with the verificationId when the SMS is sent.
  /// Calls [onError] with a human-readable message on failure.
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    void Function(PhoneAuthCredential credential)? onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-retrieval on Android — sign in immediately.
        try {
          await _auth.signInWithCredential(credential);
          onAutoVerified?.call(credential);
        } catch (e) {
          onError('Auto-verification failed: $e');
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        String message;
        switch (e.code) {
          case 'invalid-phone-number':
            message = 'The phone number entered is not valid.';
            break;
          case 'too-many-requests':
            message = 'Too many requests. Please try again later.';
            break;
          case 'quota-exceeded':
            message = 'SMS quota exceeded. Try again tomorrow.';
            break;
          default:
            message = e.message ?? 'Verification failed.';
        }
        onError(message);
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Timeout — do nothing special; user can still enter OTP manually.
      },
      timeout: const Duration(seconds: 60),
    );
  }

  /// Step 2: Verify the [otp] entered by the user against [verificationId].
  /// Returns the signed-in [User] on success, or throws [FirebaseAuthException].
  Future<User?> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    final result = await _auth.signInWithCredential(credential);
    return result.user;
  }

  /// Returns the currently signed-in user, or null.
  User? get currentUser => _auth.currentUser;

  /// Sign out.
  Future<void> signOut() => _auth.signOut();
}
