import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  // --- 🔐 輔助函式：產生 Apple 登入所需的 Nonce (保留你原本的優秀邏輯) ---
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = List.generate(length, (_) => charset[DateTime.now().microsecond % charset.length]);
    return random.join();
  }

  // ============================
  // 1. 訪客登入 (新增)
  // ============================
  Future<void> _signInAsGuest() async {
    _setLoading(true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
      // 成功後，AuthGate 會自動切換到 HomeScreen
    } on FirebaseAuthException catch (e) {
      _showErrorDialog("訪客登入失敗", e.message ?? "發生未知錯誤");
    } finally {
      if (mounted) _setLoading(false);
    }
  }

  // ============================
  // 2. Google 登入 (優化版)
  // ============================
  Future<void> _signInWithGoogle() async {
    _setLoading(true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        if (mounted) _setLoading(false);
        return; // 使用者取消登入
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      _showErrorDialog("Google 登入失敗", e.message ?? "請檢查網路或帳號設定");
    } catch (e) {
      _showErrorDialog("登入中斷", "無法完成 Google 登入: $e");
    } finally {
      if (mounted) _setLoading(false);
    }
  }

  // ============================
  // 3. Apple 登入 (支援雙平台)
  // ============================
  Future<void> _signInWithApple() async {
    _setLoading(true);
    try {
      if (Platform.isIOS) {
        // 🍎 iOS 原生體驗：使用 FaceID/TouchID 與 Nonce 防護
        final rawNonce = _generateNonce();
        final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: hashedNonce,
        );

        final credential = OAuthProvider("apple.com").credential(
          idToken: appleCredential.identityToken,
          rawNonce: rawNonce,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
      } else {
        // 🤖 Android 體驗：透過 Firebase 彈出 Apple 網頁驗證
        final provider = OAuthProvider("apple.com");
        provider.addScope('email');
        provider.addScope('name');

        // signInWithProvider 會自動處理 Android 上的跳轉與回調
        await FirebaseAuth.instance.signInWithProvider(provider);
      }
    } on FirebaseAuthException catch (e) {
      _showErrorDialog("Apple 登入失敗", e.message ?? "發生未知錯誤");
    } catch (e) {
      debugPrint("Apple Sign In Canceled or Error: $e");
    } finally {
      if (mounted) _setLoading(false);
    }
  }

  // --- UI 輔助方法 ---
  void _setLoading(bool value) {
    setState(() => _isLoading = value);
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("確定")),
        ],
      ),
    );
  }

  // ============================
  // 畫面建構 (全新適配深淺色模式 UI)
  // ============================
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF121212), const Color(0xFF1E293B)]
                    : [Colors.blue.shade50, Colors.white],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.monitor_heart_rounded, size: 80, color: Colors.blue.shade600),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "CareSync 健康隨行",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.blueGrey.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "記錄您的臨床進度\n為您量身打造的健康追蹤工具",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey.shade400 : Colors.blueGrey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 50),

                    _buildLoginButton(
                      icon: Icons.g_mobiledata_rounded,
                      iconSize: 40,
                      label: "使用 Google 帳號登入",
                      backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
                      textColor: isDark ? Colors.white : Colors.black87,
                      borderColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      onPressed: _signInWithGoogle,
                    ),
                    const SizedBox(height: 16),

                    // 🚀 核心修正：Android 也要顯示 Apple 登入，解決跨平台遷移問題
                    // 且 iOS 必須顯示，否則無法通過審核
                    _buildLoginButton(
                      icon: Icons.apple_rounded,
                      iconSize: 28,
                      label: "使用 Apple 帳號登入",
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      textColor: isDark ? Colors.black : Colors.white,
                      borderColor: Colors.transparent,
                      onPressed: _signInWithApple,
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 24),

                    // 分隔線效果
                    Row(
                      children: [
                        Expanded(child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text("或", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ),
                        Expanded(child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 3. 訪客登入
                    _buildLoginButton(
                      icon: Icons.person_outline_rounded,
                      iconSize: 26,
                      label: "以訪客身分快速開始",
                      backgroundColor: Colors.blue.shade600,
                      textColor: Colors.white,
                      borderColor: Colors.transparent,
                      onPressed: _signInAsGuest,
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: Card(
                  elevation: 8,
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- 統一的按鈕元件 ---
  Widget _buildLoginButton({
    required IconData icon,
    required double iconSize,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required Color borderColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: borderColor, width: 1.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}