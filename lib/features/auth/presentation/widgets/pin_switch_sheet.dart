import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../providers/session_provider.dart';

/// Fast PIN quick-switch — swap the active staff member during service without
/// re-entering email/password. (Terminal stays logged in.)
class PinSwitchSheet extends ConsumerStatefulWidget {
  const PinSwitchSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => const PinSwitchSheet(),
    );
  }

  @override
  ConsumerState<PinSwitchSheet> createState() => _PinSwitchSheetState();
}

class _PinSwitchSheetState extends ConsumerState<PinSwitchSheet> {
  String _pin = '';
  String? _error;

  void _tap(String d) {
    if (_pin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length == 4) _check();
  }

  void _back() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _check() {
    final match = kStaffMembers.where((s) => s.pin == _pin).toList();
    if (match.isEmpty) {
      setState(() {
        _error = 'Invalid PIN';
        _pin = '';
      });
      return;
    }
    ref.read(activeUserProvider.notifier).state = match.first;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Switched to ${match.first.name} · ${match.first.role}'),
      duration: const Duration(milliseconds: 1100),
      backgroundColor: AppColors.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTones(ref.watch(themeProvider));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.lock_open_outlined,
                      color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Switch User',
                          style: TextStyle(
                              color: t.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 17)),
                      Text('Enter your 4-digit PIN',
                          style: TextStyle(color: t.textMuted, fontSize: 12.5)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: t.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ]),
              const SizedBox(height: 20),
              // PIN dots.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < 4; i++)
                    Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: i < _pin.length
                            ? AppColors.accent
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: _error != null
                                ? AppColors.error
                                : (i < _pin.length
                                    ? AppColors.accent
                                    : t.border),
                            width: 1.6),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 18,
                child: _error != null
                    ? Text(_error!,
                        style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5))
                    : Text('Demo · Admin PIN 0000',
                        style: TextStyle(color: t.textMuted, fontSize: 11.5)),
              ),
              const SizedBox(height: 14),
              // Keypad.
              for (final row in const [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [for (final d in row) _key(t, d)],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 64, child: const SizedBox()),
                  _key(t, '0'),
                  _key(t, '⌫', onTap: _back),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _key(AppTones t, String label, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap ?? () => _tap(label),
          child: Container(
            width: 64,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: t.border),
            ),
            child: Text(label,
                style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
