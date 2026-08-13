import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:azberry_customer/core/i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _codeSent = false;
  bool _emailMode = false; // email/password login (for testing without SMS)
  bool _loading = false;
  String? _error;

  static const _dialCode = '+964'; // Iraq default

  String get _fullPhone {
    var p = _phone.text.trim().replaceAll(' ', '');
    if (p.startsWith('0')) p = p.substring(1);
    return '$_dialCode$p';
  }

  Future<void> _sendOtp() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(supabaseProvider).auth.signInWithOtp(phone: _fullPhone);
      setState(() => _codeSent = true);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = tr('تعذّر إرسال الرمز. تأكّد من إعداد مزوّد الرسائل.'));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(supabaseProvider).auth.verifyOTP(
            phone: _fullPhone,
            token: _otp.text.trim(),
            type: OtpType.sms,
          );
      if (mounted) context.go('/');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _emailLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(supabaseProvider).auth.signInWithPassword(
            email: _email.text.trim(),
            password: _password.text,
          );
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
                  child: Image.asset('assets/logo.jpg', width: 200),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                tr('طازج… ويوصل لباب بيتك'),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 32),
              if (_emailMode) ...[
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: tr('البريد الإلكتروني'),
                    hintText: 'cust1@test.com',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(labelText: tr('كلمة المرور')),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _emailLogin,
                  child: Text(_loading ? tr('جارِ الدخول…') : tr('تسجيل الدخول')),
                ),
              ] else if (!_codeSent) ...[
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: tr('رقم الهاتف'),
                    prefixText: '$_dialCode ',
                    hintText: '7XX XXX XXXX',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _sendOtp,
                  child: Text(_loading ? tr('جارِ الإرسال…') : tr('إرسال رمز التحقق')),
                ),
              ] else ...[
                TextField(
                  controller: _otp,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: tr('رمز التحقق'),
                    hintText: '● ● ● ● ● ●',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _verify,
                  child: Text(_loading ? tr('جارِ التحقق…') : tr('تأكيد')),
                ),
                TextButton(
                  onPressed: () => setState(() => _codeSent = false),
                  child: Text(tr('تغيير الرقم')),
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              const Spacer(),
              // Test-only email/password sign-in. Hidden in release builds so it
              // is not available to end users in production.
              if (!kReleaseMode)
                TextButton(
                  onPressed: () => setState(() {
                    _emailMode = !_emailMode;
                    _codeSent = false;
                    _error = null;
                  }),
                  child: Text(_emailMode ? tr('الدخول برقم الهاتف') : tr('دخول تجريبي بالبريد الإلكتروني')),
                ),
              TextButton(
                onPressed: () => context.go('/'),
                child: Text(tr('تصفّح كضيف')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
