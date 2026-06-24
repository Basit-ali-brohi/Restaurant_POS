import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr/qr.dart';

import '../../../../core/database/db_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../audit/presentation/providers/audit_provider.dart';
import '../../../auth/presentation/providers/session_provider.dart';

class _TaxProfile {
  final String name;
  final String authority;
  double rate; // percent
  bool enabled;
  _TaxProfile(this.name, this.authority, this.rate, this.enabled);
}

/// SCREENS 67–68 — Tax Settings Engine. Localized tax profiles (GST/VAT) linked
/// to a simulated real-time FBR/SRB fiscal sync channel and QR print output.
class TaxSettingsScreen extends ConsumerStatefulWidget {
  const TaxSettingsScreen({super.key});

  @override
  ConsumerState<TaxSettingsScreen> createState() => _TaxSettingsScreenState();
}

class _TaxSettingsScreenState extends ConsumerState<TaxSettingsScreen> {
  final List<_TaxProfile> _profiles = [
    _TaxProfile('GST (Federal)', 'FBR', 17.0, true),
    _TaxProfile('Sindh Sales Tax', 'SRB', 13.0, true),
    _TaxProfile('Punjab Sales Tax', 'PRA', 16.0, false),
    _TaxProfile('VAT (Export)', 'FBR', 5.0, false),
  ];

  bool _syncing = false;
  String _lastSync = '2 minutes ago';
  bool _qrEnabled = true;
  int _invoiceSeq = 84120;
  final List<({String irn, String at, int count})> _syncLog = [];

  final _db = DbService.instance;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  /// Restores saved tax rates + toggles from MySQL (app_state key "tax").
  Future<void> _loadConfig() async {
    if (!_db.isConnected) return;
    final raw = await _db.loadState('tax');
    if (raw == null || raw.isEmpty) return;
    final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final saved = (data['profiles'] as List?) ?? const [];
    if (!mounted) return;
    setState(() {
      for (final s in saved) {
        final m = Map<String, dynamic>.from(s as Map);
        final p = _profiles.where((p) => p.name == m['name']).toList();
        if (p.isNotEmpty) {
          p.first.rate = (m['rate'] as num).toDouble();
          p.first.enabled = m['enabled'] as bool;
        }
      }
      _qrEnabled = data['qrEnabled'] as bool? ?? _qrEnabled;
    });
  }

  void _saveConfig() {
    _db.saveState(
        'tax',
        jsonEncode({
          'profiles': _profiles
              .map((p) => {
                    'name': p.name,
                    'rate': p.rate,
                    'enabled': p.enabled,
                  })
              .toList(),
          'qrEnabled': _qrEnabled,
        }));
  }

  List<List<bool>> _qr(String data) {
    final code =
        QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M);
    final img = QrImage(code);
    final n = img.moduleCount;
    return List.generate(n, (r) => List.generate(n, (c) => img.isDark(r, c)));
  }

  String _generateIrn() {
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return 'FBR-$stamp-${(++_invoiceSeq)}';
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    // Simulated FBR response: a batch of invoices posted, each receiving a
    // fiscal Invoice Reference Number (IRN).
    final batch = 3 + (DateTime.now().second % 9);
    final irn = _generateIrn();
    final now = TimeOfDay.now();
    final at = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
    setState(() {
      _syncing = false;
      _lastSync = 'Just now';
      _syncLog.insert(0, (irn: irn, at: at, count: batch));
      if (_syncLog.length > 4) _syncLog.removeLast();
    });
    ref.read(auditTrailProvider.notifier).log(
          category: AuditCategory.system,
          action: 'Fiscal sync with FBR / SRB',
          detail: '$batch invoices posted · IRN $irn',
          actor: ref.read(activeUserProvider).name,
        );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$batch invoices posted to FBR · IRN $irn'),
      duration: const Duration(milliseconds: 1400),
      backgroundColor: AppColors.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTones(ref.watch(themeProvider));

    return Container(
      color: t.canvas,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tax Settings',
                style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            Text('Localized tax profiles, fiscal synchronization and QR invoicing.',
                style: TextStyle(color: t.textMuted, fontSize: 13)),
            const SizedBox(height: 18),
            LayoutBuilder(builder: (context, c) {
              final stacked = c.maxWidth < 980;
              final left = _profilesCard(t);
              final right = Column(children: [
                _syncCard(t),
                const SizedBox(height: 16),
                _qrCard(t),
              ]);
              if (stacked) {
                return Column(children: [left, const SizedBox(height: 16), right]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: left),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: right),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _profilesCard(AppTones t) {
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Text('Tax Profiles',
                style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ),
          Divider(height: 1, color: t.border),
          for (int i = 0; i < _profiles.length; i++)
            _profileRow(t, _profiles[i], i == _profiles.length - 1),
        ],
      ),
    );
  }

  Widget _profileRow(AppTones t, _TaxProfile p, bool last) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: t.border))),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8)),
          child: Text(p.authority,
              style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 12)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name,
                  style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              Text('Authority: ${p.authority}',
                  style: TextStyle(color: t.textMuted, fontSize: 11.5)),
            ],
          ),
        ),
        // Rate stepper.
        _rateStep(t, Icons.remove, () {
          setState(() => p.rate = (p.rate - 0.5).clamp(0, 40));
          _saveConfig();
        }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('${p.rate.toStringAsFixed(p.rate % 1 == 0 ? 0 : 1)}%',
              style: TextStyle(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
        ),
        _rateStep(t, Icons.add, () {
          setState(() => p.rate = (p.rate + 0.5).clamp(0, 40));
          _saveConfig();
        }),
        const SizedBox(width: 14),
        Switch(
          value: p.enabled,
          activeThumbColor: AppColors.accent,
          onChanged: (v) {
            setState(() => p.enabled = v);
            _saveConfig();
          },
        ),
      ]),
    );
  }

  Widget _rateStep(AppTones t, IconData icon, VoidCallback onTap) {
    return Material(
      color: t.surfaceAlt,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: t.border)),
          child: Icon(icon, size: 15, color: t.textPrimary),
        ),
      ),
    );
  }

  Widget _syncCard(AppTones t) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.sync, color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fiscal Sync (FBR / SRB)',
                      style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5)),
                  Row(children: [
                    Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                            color: AppColors.success, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('Connected · last sync $_lastSync',
                        style: TextStyle(color: t.textMuted, fontSize: 11.5)),
                  ]),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _syncing ? null : _sync,
              icon: _syncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.cloud_sync, size: 18),
              label: Text(_syncing ? 'Syncing…' : 'Sync Now',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          if (_syncLog.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('RECENT SUBMISSIONS',
                style: TextStyle(
                    color: t.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8)),
            const SizedBox(height: 8),
            for (final s in _syncLog)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  const Icon(Icons.verified_outlined,
                      size: 15, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(s.irn,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                  ),
                  Text('${s.count} inv · ${s.at}',
                      style: TextStyle(color: t.textMuted, fontSize: 11)),
                ]),
              ),
          ],
        ],
      ),
    );
  }

  Widget _qrCard(AppTones t) {
    final matrix = _qr('FBR|NTN:1234567|POS:CPOS-04|INV-VERIFY');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text('FBR QR Invoicing',
                  style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ),
            Switch(
              value: _qrEnabled,
              activeThumbColor: AppColors.accent,
              onChanged: (v) {
                setState(() => _qrEnabled = v);
                _saveConfig();
              },
            ),
          ]),
          Text('Print a verifiable fiscal QR on every receipt.',
              style: TextStyle(color: t.textMuted, fontSize: 12)),
          const SizedBox(height: 14),
          Center(
            child: Opacity(
              opacity: _qrEnabled ? 1 : 0.3,
              child: Container(
                padding: const EdgeInsets.all(10),
                color: Colors.white,
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(painter: _QrPainter(matrix)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(_qrEnabled ? 'QR printing enabled' : 'QR printing disabled',
                style: TextStyle(color: t.textMuted, fontSize: 11.5)),
          ),
        ],
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.matrix);
  final List<List<bool>> matrix;
  @override
  void paint(Canvas canvas, Size size) {
    final n = matrix.length;
    if (n == 0) return;
    final cell = size.width / n;
    final paint = Paint()..color = const Color(0xFF111111);
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (matrix[r][c]) {
          canvas.drawRect(
              Rect.fromLTWH(c * cell, r * cell, cell + 0.5, cell + 0.5), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter old) => old.matrix != matrix;
}
