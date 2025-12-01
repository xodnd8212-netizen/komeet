import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../i18n/i18n.dart';
import '../../services/auth_service.dart';
import '../../services/admin_service.dart';
import '../../theme/theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final result = _isSignUp
          ? await AuthService.createUserWithEmailAndPassword(email, password)
          : await AuthService.signInWithEmailAndPassword(email, password);

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (result != null) {
        // 어드민 여부 확인
        final isAdmin = await AdminService.isAdmin();
        if (isAdmin) {
          context.go('/admin');
        } else {
          context.go('/profile');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleSocialLogin(
    Future<UserCredential?> Function() action,
  ) async {
    setState(() => _isLoading = true);

    try {
      final result = await action();
      setState(() => _isLoading = false);

      if (!mounted) return;

      if (result != null) {
        // 어드민 여부 확인
        final isAdmin = await AdminService.isAdmin();
        if (isAdmin) {
          context.go('/admin');
        } else {
          context.go('/profile');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _openPolicy(String policyId) {
    context.push('/policy/$policyId');
  }

  @override
  Widget build(BuildContext context) {
    final i18n = I18n.of(context);
    final isAppleSupported =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.pink.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 48,
                      color: AppTheme.pink,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '코밋 Komeet',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.pink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    i18n.t('login.subtitle'),
                    style: const TextStyle(color: AppTheme.sub),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    i18n.t('login.age_notice'),
                    style: const TextStyle(
                      color: AppTheme.sub,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: i18n.t('login.email'),
                      labelStyle: const TextStyle(color: AppTheme.sub),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: AppTheme.card,
                      prefixIcon: const Icon(Icons.email, color: AppTheme.sub),
                    ),
                    style: const TextStyle(color: AppTheme.text),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return i18n.t('login.email_required');
                      }
                      if (!v.contains('@')) {
                        return i18n.t('login.email_invalid');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: i18n.t('login.password'),
                      labelStyle: const TextStyle(color: AppTheme.sub),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: AppTheme.card,
                      prefixIcon: const Icon(Icons.lock, color: AppTheme.sub),
                    ),
                    style: const TextStyle(color: AppTheme.text),
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return i18n.t('login.password_required');
                      }
                      if (v.length < 6) {
                        return i18n.t('login.password_min');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.pink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              _isSignUp
                                  ? i18n.t('login.signup')
                                  : i18n.t('login.signin'),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp
                          ? i18n.t('login.have_account')
                          : i18n.t('login.no_account'),
                      style: const TextStyle(color: AppTheme.sub),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      i18n.t('login.policies_prompt'),
                      style: const TextStyle(color: AppTheme.sub),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => _openPolicy('community'),
                        child: Text(
                          i18n.t('policy.community'),
                          style: const TextStyle(color: AppTheme.sub),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _openPolicy('terms'),
                        child: Text(
                          i18n.t('policy.terms'),
                          style: const TextStyle(color: AppTheme.sub),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _openPolicy('privacy'),
                        child: Text(
                          i18n.t('policy.privacy'),
                          style: const TextStyle(color: AppTheme.sub),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppTheme.line)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          i18n.t('login.or'),
                          style: const TextStyle(color: AppTheme.sub),
                        ),
                      ),
                      Expanded(child: Divider(color: AppTheme.line)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (isAppleSupported) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _handleSocialLogin(
                                AuthService.signInWithApple,
                              ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.text,
                          side: const BorderSide(color: AppTheme.line),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.apple),
                        label: Text(i18n.t('login.social.apple')),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => _handleSocialLogin(
                              AuthService.signInWithGoogle,
                            ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.text,
                        side: const BorderSide(color: AppTheme.line),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.g_mobiledata),
                      label: Text(i18n.t('login.social.google')),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () =>
                                _handleSocialLogin(AuthService.signInWithKakao),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.text,
                        side: const BorderSide(color: AppTheme.line),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: Text(i18n.t('login.social.kakao')),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () =>
                                _handleSocialLogin(AuthService.signInWithNaver),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.text,
                        side: const BorderSide(color: AppTheme.line),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.eco_outlined),
                      label: Text(i18n.t('login.social.naver')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
