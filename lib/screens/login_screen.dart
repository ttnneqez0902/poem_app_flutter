import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  // --- 🔐 輔助函式：產生 Apple 登入所需的 Nonce ---
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = List.generate(length, (_) => charset[DateTime.now().microsecond % charset.length]);
    return random.join(); // 回傳原始字串
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monitor_heart_rounded, size: 80, color: Colors.blue),
                  const SizedBox(height: 20),
                  const Text("臨床數據雲端同步",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 10),
                  const Text("登入後即可在不同裝置同步紀錄",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 50),

                  // Google 登入
                  _loginButton(
                    label: "使用 Google 登入",
                    icon: FontAwesomeIcons.google,
                    color: Colors.white,
                    textColor: Colors.black87,
                    onPressed: _isLoading ? null : () => _handleGoogleSignIn(),
                  ),
                  const SizedBox(height: 16),

                  // Apple 登入 (通常建議只在 iOS 顯示，或確認 Web 支援)
                  _loginButton(
                    label: "使用 Apple 登入",
                    icon: FontAwesomeIcons.apple,
                    color: Colors.black,
                    textColor: Colors.white,
                    onPressed: _isLoading ? null : () => _handleAppleSignIn(),
                  ),
                  const SizedBox(height: 16),

                  // LINE 登入
                  _loginButton(
                    label: "使用 LINE 登入",
                    icon: FontAwesomeIcons.line,
                    color: const Color(0xFF06C755),
                    textColor: Colors.white,
                    onPressed: _isLoading ? null : () => _handleLineSignIn(),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _loginButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: FaIcon(icon, color: textColor),
        label: Text(label, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }

  // --- 🔐 登入邏輯實作區 ---

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      // 🚀 修正 1：改用具名實例呼叫
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 🚀 修正 2：處理可能為 null 的 token (使用 ! 或預設值)
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      _showErrorSnackBar("Google 登入失敗: $e");
    } finally {
      // 🚀 修正 3：加入 mounted 檢查
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final rawNonce = _generateNonce();
      // Apple 登入需要將 rawNonce 進行 sha256 雜湊後傳入
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce, // 這裡傳雜湊後的
      );

      final OAuthCredential credential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce, // 這裡傳原始的
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      _showErrorSnackBar("Apple 登入失敗: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLineSignIn() async {
    setState(() => _isLoading = true);
    try {
      final result = await LineSDK.instance.login();
      // 注意：Firebase 不直接支援 LINE
      // 這邊通常需要串接後端 Cloud Functions 使用自定義 Token
      // 或暫時僅使用 LINE SDK 獲取資料
      debugPrint("LINE 使用者名稱: ${result.userProfile?.displayName}");

      // 💡 如果你沒有 Cloud Function，這裡無法直接登入 Firebase
      // 你可能需要跳過 Firebase 驗證或實作 Custom Auth
    } catch (e) {
      _showErrorSnackBar("LINE 登入失敗: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}