import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';

/// SCREENS 3–5 — Forgot Password → 6-digit Verify → Reset, as full-screen split
/// pages matching the CloudPOS Pro reference (indigo VERIFY, black SAVE).
class PasswordRecoveryFlow extends ConsumerStatefulWidget {
  const PasswordRecoveryFlow({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PasswordRecoveryFlow()),
    );
  }

  @override
  ConsumerState<PasswordRecoveryFlow> createState() =>
      _PasswordRecoveryFlowState();
}

enum _Step { email, otp, reset, done }

class _PasswordRecoveryFlowState extends ConsumerState<PasswordRecoveryFlow> {
  _Step _step = _Step.email;
  String? _error;

  final _email = TextEditingController();
  final List<TextEditingController> _otp =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpNodes = List.generate(6, (_) => FocusNode());
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure1 = true, _obscure2 = true;

  static const _heroImage =
      'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1200&q=80';

  @override
  void dispose() {
    _email.dispose();
    for (final c in _otp) {
      c.dispose();
    }
    for (final n in _otpNodes) {
      n.dispose();
    }
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _advance() {
    setState(() => _error = null);
    switch (_step) {
      case _Step.email:
        if (_email.text.trim().isEmpty) {
          return setState(() => _error = 'Enter your email to continue');
        }
        setState(() => _step = _Step.otp);
        break;
      case _Step.otp:
        final code = _otp.map((c) => c.text).join();
        if (code.length < 6) {
          return setState(() => _error = 'Enter the full 6-digit code');
        }
        // Demo: any 6-digit code is accepted.
        setState(() => _step = _Step.reset);
        break;
      case _Step.reset:
        if (_pass.text.length < 8) {
          return setState(() => _error = 'Minimum 8 characters');
        }
        if (_pass.text != _confirm.text) {
          return setState(() => _error = 'Passwords do not match');
        }
        setState(() => _step = _Step.done);
        break;
      case _Step.done:
        Navigator.of(context).pop();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTones(ref.watch(themeProvider));
    return Scaffold(
      backgroundColor: t.isDark ? const Color(0xFF14121F) : const Color(0xFFF4F4FB),
      body: LayoutBuilder(builder: (context, c) {
        final showHero = c.maxWidth >= 820;
        return Row(
          children: [
            if (showHero) Expanded(child: _hero(t)),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: _body(t),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // --- Left hero -------------------------------------------------------------
  Widget _hero(AppTones t) {
    final quote = _step == _Step.reset
        ? 'Secure your access.\nProtect your operations.'
        : '"Precision in every order. Control in every transaction."';
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(_heroImage, fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(color: const Color(0xFF14121F))),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.55),
                const Color(0xFF14121F).withValues(alpha: 0.92),
              ],
            ),
          ),
        ),
        Positioned(
          left: 40,
          top: 40,
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text('CloudPOS Pro',
                style: GoogleFonts.teko(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 1)),
          ]),
        ),
        Positioned(
          left: 40,
          right: 40,
          bottom: 60,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(quote,
                  style: GoogleFonts.teko(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      height: 1.05)),
              const SizedBox(height: 14),
              Text(
                _step == _Step.reset
                    ? 'Set a strong password to keep your terminal secure.'
                    : 'Securely authenticate to access your restaurant management dashboard.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8), fontSize: 13.5),
              ),
              const SizedBox(height: 18),
              // Step progress.
              Row(children: [
                for (int i = 0; i < 3; i++)
                  Container(
                    width: 28,
                    height: 4,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: _step.index >= i
                          ? (_step == _Step.reset
                              ? const Color(0xFFE3B041)
                              : AppColors.accent)
                          : Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  // --- Right body ------------------------------------------------------------
  Widget _body(AppTones t) {
    final heading = t.isDark ? Colors.white : const Color(0xFF312E81);
    switch (_step) {
      case _Step.email:
        return _emailBody(t, heading);
      case _Step.otp:
        return _otpBody(t, heading);
      case _Step.reset:
        return _resetBody(t, heading);
      case _Step.done:
        return _doneBody(t, heading);
    }
  }

  Widget _lockBadge(AppTones t) => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.12),
            shape: BoxShape.circle),
        child: const Icon(Icons.lock_open_outlined,
            color: AppColors.accent, size: 26),
      );

  Widget _emailBody(AppTones t, Color heading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _lockBadge(t),
        const SizedBox(height: 18),
        Text('Forgot password',
            style: GoogleFonts.teko(
                color: heading, fontSize: 34, fontWeight: FontWeight.w700, height: 1)),
        const SizedBox(height: 4),
        Text('Enter your account email and we will send a 6-digit code.',
            style: TextStyle(color: t.textMuted, fontSize: 13.5)),
        const SizedBox(height: 24),
        _label(t, 'EMAIL'),
        _input(t, _email, 'you@restaurant.com'),
        _errorRow(),
        const SizedBox(height: 22),
        _indigoButton('SEND CODE'),
        const SizedBox(height: 16),
        _backToLogin(),
      ],
    );
  }

  Widget _otpBody(AppTones t, Color heading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _lockBadge(t),
        const SizedBox(height: 18),
        Text('Verify your account',
            style: GoogleFonts.teko(
                color: heading, fontSize: 34, fontWeight: FontWeight.w700, height: 1)),
        const SizedBox(height: 4),
        Text("We've sent a 6-digit code to your email. Enter it below to continue.",
            style: TextStyle(color: t.textMuted, fontSize: 13.5)),
        const SizedBox(height: 26),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (int i = 0; i < 6; i++)
              SizedBox(
                width: 58,
                height: 68,
                child: TextField(
                  controller: _otp[i],
                  focusNode: _otpNodes[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: t.isDark ? t.surfaceAlt : Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: t.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.accent, width: 1.8),
                    ),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty && i < 5) _otpNodes[i + 1].requestFocus();
                    if (v.isEmpty && i > 0) _otpNodes[i - 1].requestFocus();
                  },
                ),
              ),
          ],
        ),
        _errorRow(),
        const SizedBox(height: 22),
        _indigoButton('VERIFY'),
        const SizedBox(height: 16),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Didn't receive the code? ",
                  style: TextStyle(color: t.textMuted, fontSize: 13)),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Code resent'),
                      duration: Duration(milliseconds: 900)),
                ),
                child: const Text('Resend code',
                    style: TextStyle(
                        color: AppColors.accent, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _resetBody(AppTones t, Color heading) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: t.isDark ? t.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 30,
              offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reset Password',
              style: GoogleFonts.teko(
                  color: heading, fontSize: 30, fontWeight: FontWeight.w700, height: 1)),
          const SizedBox(height: 4),
          Text('Please enter your new security credentials below to regain access to your terminal.',
              style: TextStyle(color: t.textSecondary, fontSize: 13.5, height: 1.4)),
          const SizedBox(height: 22),
          _label(t, 'NEW PASSWORD'),
          _input(t, _pass, '••••••••',
              obscure: _obscure1,
              trailing: IconButton(
                icon: Icon(
                    _obscure1 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 19, color: t.textMuted),
                onPressed: () => setState(() => _obscure1 = !_obscure1),
              )),
          const SizedBox(height: 16),
          _label(t, 'CONFIRM PASSWORD'),
          _input(t, _confirm, '••••••••',
              obscure: _obscure2,
              trailing: IconButton(
                icon: Icon(
                    _obscure2 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 19, color: t.textMuted),
                onPressed: () => setState(() => _obscure2 = !_obscure2),
              )),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Minimum 8 characters, including a number and a symbol.',
                    style: TextStyle(color: t.textSecondary, fontSize: 12.5)),
              ),
            ]),
          ),
          _errorRow(),
          const SizedBox(height: 20),
          // Black primary (per reference).
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _advance,
              style: ElevatedButton.styleFrom(
                backgroundColor: t.isDark ? const Color(0xFF15151E) : Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                side: t.isDark ? BorderSide(color: t.border) : BorderSide.none,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('SAVE PASSWORD',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 1.0)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 17),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(child: _backToLogin()),
        ],
      ),
    );
  }

  Widget _doneBody(AppTones t, Color heading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.14),
              shape: BoxShape.circle),
          child: const Icon(Icons.check_circle, color: AppColors.success, size: 44),
        ),
        const SizedBox(height: 18),
        Text('Password updated',
            style: GoogleFonts.teko(
                color: heading, fontSize: 32, fontWeight: FontWeight.w700, height: 1)),
        const SizedBox(height: 6),
        Text('You can now sign in with your new credentials.',
            textAlign: TextAlign.center,
            style: TextStyle(color: t.textMuted, fontSize: 13.5)),
        const SizedBox(height: 24),
        _indigoButton('BACK TO LOGIN'),
      ],
    );
  }

  // --- Shared bits -----------------------------------------------------------
  Widget _indigoButton(String label) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _advance,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 1.0)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 17),
          ],
        ),
      ),
    );
  }

  Widget _backToLogin() => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back, size: 15, color: AppColors.accent),
            SizedBox(width: 6),
            Text('Back to Login',
                style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5)),
          ],
        ),
      );

  Widget _errorRow() {
    if (_error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(children: [
        const Icon(Icons.error_outline, size: 15, color: AppColors.error),
        const SizedBox(width: 6),
        Expanded(
          child: Text(_error!,
              style: const TextStyle(color: AppColors.error, fontSize: 12.5)),
        ),
      ]),
    );
  }

  Widget _label(AppTones t, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6)),
      );

  Widget _input(AppTones t, TextEditingController c, String hint,
      {bool obscure = false, Widget? trailing}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      style: TextStyle(color: t.textPrimary, fontSize: 14.5),
      decoration: InputDecoration(
        suffixIcon: trailing,
        hintText: hint,
        hintStyle: TextStyle(color: t.textMuted, fontSize: 14),
        filled: true,
        fillColor: t.isDark ? t.surfaceAlt : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: t.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
        ),
      ),
    );
  }
}
