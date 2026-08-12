import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/app_theme.dart';
import '../providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(supabaseProvider).auth.signInWithPassword(
            email: _email.text.trim(),
            password: _password.text,
          );
      // Verify this account is actually a driver.
      final driver = await ref.read(driverRepoProvider).me();
      if (driver == null) {
        await ref.read(supabaseProvider).auth.signOut();
        setState(() => _error = 'هذا الحساب ليس مسجّلاً كسائق. تواصل مع الإدارة.');
        return;
      }
      if (mounted) context.go('/');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('assets/logo.jpg', width: 180),
                ),
              ),
              const SizedBox(height: 12),
              const Text('تطبيق السائق',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const Text('سجّل الدخول لبدء استلام الطلبات',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 28),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(labelText: 'كلمة المرور'),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!,
                      textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _login,
                child: Text(_loading ? 'جارِ الدخول…' : 'تسجيل الدخول'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
