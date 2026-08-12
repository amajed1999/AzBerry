import 'package:flutter/material.dart';
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
  bool _codeSent = false;
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
      setState(() => _error = 'تعذّر إرسال الرمز. تأكّد من إعداد مزوّد الرسائل.');
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
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Text('🫐', style: TextStyle(fontSize: 44)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'AzBerry',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const Text(
                'طازج… ويوصل لباب بيتك',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 32),
              if (!_codeSent) ...[
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    prefixText: '$_dialCode ',
                    hintText: '7XX XXX XXXX',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _sendOtp,
                  child: Text(_loading ? 'جارِ الإرسال…' : 'إرسال رمز التحقق'),
                ),
              ] else ...[
                TextField(
                  controller: _otp,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: 'رمز التحقق',
                    hintText: '● ● ● ● ● ●',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _verify,
                  child: Text(_loading ? 'جارِ التحقق…' : 'تأكيد'),
                ),
                TextButton(
                  onPressed: () => setState(() => _codeSent = false),
                  child: const Text('تغيير الرقم'),
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
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('تصفّح كضيف'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
