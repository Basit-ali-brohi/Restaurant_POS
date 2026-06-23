import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/shell/app_shell.dart';
import '../widgets/password_recovery_flow.dart';

/// SCREEN 1/2 — Login. Split panel: branded kitchen visual (left) and an
/// email/password sign-in form (right), matching the CloudPOS Pro reference.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController(text: '');
  final _password = TextEditingController();
  bool _obscure = true;
  bool _remember = false;
  bool _loading = false;

  static const _heroImage =
      'https://images.unsplash.com/photo-1556910103-1c02745aae4d?auto=format&fit=crop&w=1200&q=80';

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTones(ref.watch(themeProvider));
    final heading = t.isDark ? Colors.white : const Color(0xFF312E81);

    return Scaffold(
      backgroundColor: t.isDark ? const Color(0xFF0B0B12) : const Color(0xFFEDEDF4),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180, maxHeight: 820),
            child: LayoutBuilder(builder: (context, c) {
              final showHero = c.maxWidth >= 820;
              return Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 50,
                        offset: const Offset(0, 24)),
                  ],
                ),
                child: Row(
                  children: [
                    if (showHero) Expanded(child: _hero()),
                    Expanded(child: _form(t, heading)),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // --- Left: branded hero ----------------------------------------------------
  Widget _hero() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(_heroImage, fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(color: const Color(0xFF1E1B33))),
        // Indigo wash that deepens toward the bottom.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1E1B33).withValues(alpha: 0.35),
                const Color(0xFF2E2569).withValues(alpha: 0.65),
                const Color(0xFF4F46E5).withValues(alpha: 0.92),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        Positioned(
          left: 36,
          right: 36,
          bottom: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.restaurant, color: Color(0xFFE3B041), size: 28),
                  const SizedBox(width: 10),
                  Text('CloudPOS Pro',
                      style: GoogleFonts.teko(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          height: 1)),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Precision management for high-volume culinary environments. Secure, scalable, and built for speed.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Right: sign-in form ---------------------------------------------------
  Widget _form(AppTones t, Color heading) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome back',
              style: GoogleFonts.teko(
                  color: heading,
                  fontSize: 52,
                  fontWeight: FontWeight.w700,
                  height: 1)),
          const SizedBox(height: 6),
          Text('Please enter your details to access your branch dashboard.',
              style: TextStyle(color: t.textMuted, fontSize: 14)),
          const SizedBox(height: 30),
          _label(t, 'Email / Username'),
          _field(t,
              controller: _email,
              hint: 'admin@mainbranch.com',
              icon: Icons.person_outline),
          const SizedBox(height: 18),
          _label(t, 'Password'),
          _field(t,
              controller: _password,
              hint: '••••••••',
              icon: Icons.lock_outline,
              obscure: _obscure,
              submitOnEnter: true,
              trailing: IconButton(
                icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 20,
                    color: t.textMuted),
                onPressed: () => setState(() => _obscure = !_obscure),
              )),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: _remember,
                  onChanged: (v) => setState(() => _remember = v ?? false),
                  activeColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5)),
                ),
              ),
              const SizedBox(width: 8),
              Text('Remember me',
                  style: TextStyle(color: t.textSecondary, fontSize: 13.5)),
              const Spacer(),
              GestureDetector(
                onTap: () => PasswordRecoveryFlow.show(context),
                child: const Text('Forgot password?',
                    style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Black primary action (per reference).
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _loading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: t.isDark ? const Color(0xFF15151E) : Colors.black,
                foregroundColor: Colors.white,
                disabledBackgroundColor: t.border,
                elevation: 0,
                side: t.isDark ? BorderSide(color: t.border) : BorderSide.none,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('LOGIN',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                letterSpacing: 1.0)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 28),
          Row(children: [
            Expanded(child: Divider(color: t.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('New staff member?',
                  style: TextStyle(color: t.textMuted, fontSize: 12.5)),
            ),
            Expanded(child: Divider(color: t.border)),
          ]),
          const SizedBox(height: 18),
          Center(
            child: OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Access request sent to your manager'),
                    duration: Duration(milliseconds: 1100)),
              ),
              icon: Icon(Icons.badge_outlined, size: 17, color: t.textSecondary),
              label: Text('Request access',
                  style: TextStyle(
                      color: t.textPrimary, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: t.border),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: Text('v2.4.0',
                style: TextStyle(color: t.textMuted, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _label(AppTones t, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: TextStyle(
                color: t.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      );

  Widget _field(AppTones t,
      {required TextEditingController controller,
      required String hint,
      required IconData icon,
      bool obscure = false,
      Widget? trailing,
      bool submitOnEnter = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      textInputAction:
          submitOnEnter ? TextInputAction.done : TextInputAction.next,
      onSubmitted: submitOnEnter ? (_) => _login() : null,
      style: TextStyle(color: t.textPrimary, fontSize: 14.5),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20, color: t.textMuted),
        suffixIcon: trailing,
        hintText: hint,
        hintStyle: TextStyle(color: t.textMuted, fontSize: 14),
        filled: true,
        fillColor: t.isDark ? t.surfaceAlt : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
