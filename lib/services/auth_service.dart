// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Google 登入 ---
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return await _auth.signInWithCredential(credential);
  }

  // --- Apple 登入 ---
  Future<UserCredential?> signInWithApple() async {
    final rawNonce = generateNonce(); // 需自定義 nonce 生成器
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final OAuthCredential credential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );
    return await _auth.signInWithCredential(credential);
  }

  // --- LINE 登入 (通常搭配 Firebase Custom Auth) ---
  Future<void> signInWithLine() async {
    try {
      final result = await LineSDK.instance.login();
      // LINE 登入後，通常需要將 AccessToken 傳給後端換取 Firebase Custom Token
      // 或是單純在 App 端記錄使用者資訊
      print("LINE Login Success: ${result.userProfile?.displayName}");
    } catch (e) {
      print("LINE Login Error: $e");
    }
  }
}