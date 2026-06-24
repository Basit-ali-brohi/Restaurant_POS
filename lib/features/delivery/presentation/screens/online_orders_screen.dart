import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../providers/delivery_provider.dart';

/// SCREENS 47–48 — Online Orders Panel. Incoming orders streaming from the Web
/// app and aggregator integrations (Foodpanda, Careem) with a status pipeline.
class OnlineOrdersScreen extends ConsumerWidget {
  const OnlineOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTones(ref.watch(themeProvider));
    final orders = ref.watch(onlineOrdersProvider);
    final live = orders
        .where((o) => o.status != OnlineStatus.delivered)
        .length;

    return Container(
      color: t.canvas,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Online Orders',
                      style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  Text('Live feed from Web & aggregator integration pipelines.',
                      style: TextStyle(color: t.textMuted, fontSize: 13)),
                ],
              ),
              const Spacer(),
              SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(onlineOrdersProvider.notifier).addSimulated();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('New online order received'),
                      duration: Duration(milliseconds: 1000),
                      backgroundColor: AppColors.accent,
                    ));
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Simulate Order',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: AppColors.success, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('$live live',
                      style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ]),
              ),
            ]),
            const SizedBox(height: 18),
            Wrap(spacing: 16, runSpacing: 16, children: [
              for (final ch in OrderChannel.values)
                _channelCard(t, ch,
                    orders.where((o) => o.channel == ch).length),
            ]),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: t.border),
              ),
              child: Column(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                      color: t.surfaceAlt,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(7))),
                  child: Row(children: [
                    Expanded(flex: 3, child: _h(t, 'ORDER')),
                    Expanded(flex: 2, child: _h(t, 'CHANNEL')),
                    Expanded(flex: 2, child: _h(t, 'AREA')),
                    Expanded(flex: 2, child: _h(t, 'TOTAL')),
                    Expanded(flex: 2, child: _h(t, 'STATUS')),
                    const SizedBox(width: 130),
                  ]),
                ),
                for (int i = 0; i < orders.length; i++)
                  _row(context, t, ref, orders[i], i == orders.length - 1),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _channelCard(AppTones t, OrderChannel ch, int count) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              color: ch.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(ch.icon, color: ch.color, size: 22),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$count',
              style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
          Text(ch.label, style: TextStyle(color: t.textMuted, fontSize: 12)),
        ]),
      ]),
    );
  }

  Widget _h(AppTones t, String s) => Text(s,
      style: TextStyle(
          color: t.textMuted, fontSize: 11, fontWeight: FontWeight.w700));

  Widget _row(BuildContext context, AppTones t, WidgetRef ref, OnlineOrder o,
      bool last) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: t.border))),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('#${o.id}',
                  style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5)),
              Text('${o.customer} · ${o.items} items · ${o.minsAgo}m ago',
                  style: TextStyle(color: t.textMuted, fontSize: 11.5)),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Row(children: [
            Icon(o.channel.icon, size: 14, color: o.channel.color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(o.channel.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: t.textSecondary, fontSize: 12.5)),
            ),
          ]),
        ),
        Expanded(
          flex: 2,
          child: Text(o.area,
              style: TextStyle(color: t.textSecondary, fontSize: 12.5)),
        ),
        Expanded(
          flex: 2,
          child: Text('PKR ${o.total.toStringAsFixed(2)}',
              style: TextStyle(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5)),
        ),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                  color: o.status.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(o.status.label,
                  style: TextStyle(
                      color: o.status.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 11)),
            ),
          ),
        ),
        SizedBox(
          width: 130,
          child: Align(
            alignment: Alignment.centerRight,
            child: o.status == OnlineStatus.delivered
                ? Icon(Icons.check_circle, size: 20, color: AppColors.success)
                : SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: () =>
                          ref.read(onlineOrdersProvider.notifier).advance(o.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('→ ${o.status.next.label}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 11.5)),
                    ),
                  ),
          ),
        ),
      ]),
    );
  }
}
