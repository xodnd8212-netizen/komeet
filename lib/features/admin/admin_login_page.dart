import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/admin_service.dart';
import '../../theme/theme.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adminNameController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _adminNameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isSignUp) {
        // 어드민 계정 생성
        final adminName = _adminNameController.text.trim();
        if (adminName.isEmpty) {
          throw Exception('어드민 이름을 입력해주세요.');
        }

        await AdminService.createAdminAccount(
          email: email,
          password: password,
          adminName: adminName,
        );
      } else {
        // 일반 로그인
        final result = await AuthService.signInWithEmailAndPassword(
          email,
          password,
        );

        if (result == null) {
          throw Exception('로그인에 실패했습니다.');
        }

        // 어드민 여부 확인
        final isAdmin = await AdminService.isAdmin();
        if (!isAdmin) {
          await AuthService.signOut();
          throw Exception('어드민 권한이 없습니다.');
        }
      }

      setState(() => _isLoading = false);

      if (!mounted) return;

      context.go('/admin');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.text),
          onPressed: () => context.pop(),
        ),
      ),
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
                      Icons.admin_panel_settings,
                      size: 48,
                      color: AppTheme.pink,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '어드민 로그인',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.pink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSignUp
                        ? '어드민 계정을 생성합니다'
                        : '어드민 계정으로 로그인합니다',
                    style: const TextStyle(color: AppTheme.sub),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  if (_isSignUp) ...[
                    TextFormField(
                      controller: _adminNameController,
                      decoration: InputDecoration(
                        labelText: '어드민 이름',
                        labelStyle: const TextStyle(color: AppTheme.sub),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppTheme.card,
                        prefixIcon: const Icon(Icons.person, color: AppTheme.sub),
                      ),
                      style: const TextStyle(color: AppTheme.text),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return '어드민 이름을 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: '이메일',
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
                        return '이메일을 입력해주세요.';
                      }
                      if (!v.contains('@')) {
                        return '올바른 이메일 형식이 아닙니다.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: '비밀번호',
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
                        return '비밀번호를 입력해주세요.';
                      }
                      if (v.length < 6) {
                        return '비밀번호는 최소 6자 이상이어야 합니다.';
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
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(_isSignUp ? '어드민 계정 생성' : '로그인'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp
                          ? '이미 계정이 있으신가요?'
                          : '어드민 계정 만들기',
                      style: const TextStyle(color: AppTheme.sub),
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





