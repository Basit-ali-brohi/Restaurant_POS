import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../providers/feedback_provider.dart';

/// SCREENS 74–76 — Customer Feedback. Average rating scoreboard, score
/// distribution, the review feed and a complaint-logging track.
class FeedbackScreen extends ConsumerWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTones(ref.watch(themeProvider));
    final reviews = ref.watch(reviewsProvider);
    final avg = ref.watch(averageRatingProvider);
    final dist = ref.watch(ratingDistributionProvider);
    final openComplaints =
        reviews.where((r) => r.isComplaint && !r.resolved).length;

    return Container(
      color: t.canvas,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer Feedback',
                style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            Text('Satisfaction scoreboard and complaint resolution tracking.',
                style: TextStyle(color: t.textMuted, fontSize: 13)),
            const SizedBox(height: 18),
            LayoutBuilder(builder: (context, c) {
              final stacked = c.maxWidth < 880;
              final score = _scoreboard(t, avg, reviews.length, dist);
              final complaints = _complaintsCard(context, t, ref,
                  reviews.where((r) => r.isComplaint).toList(), openComplaints);
              if (stacked) {
                return Column(children: [
                  score,
                  const SizedBox(height: 16),
                  complaints
                ]);
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 2, child: score),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: complaints),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
            Text('RECENT REVIEWS',
                style: TextStyle(
                    color: t.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0)),
            const SizedBox(height: 12),
            for (final r in reviews) _reviewCard(t, r),
          ],
        ),
      ),
    );
  }

  Widget _scoreboard(AppTones t, double avg, int total, Map<int, int> dist) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Overall Rating',
            style: TextStyle(
                color: t.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15)),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(avg.toStringAsFixed(1),
              style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  height: 1)),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('/ 5.0',
                style: TextStyle(color: t.textMuted, fontSize: 14)),
          ),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          for (int i = 1; i <= 5; i++)
            Icon(
              avg >= i
                  ? Icons.star
                  : (avg >= i - 0.5 ? Icons.star_half : Icons.star_border),
              color: const Color(0xFFE3B041),
              size: 22,
            ),
          const SizedBox(width: 8),
          Text('$total reviews',
              style: TextStyle(color: t.textMuted, fontSize: 12)),
        ]),
        const SizedBox(height: 16),
        for (int star = 5; star >= 1; star--)
          _distRow(t, star, dist[star] ?? 0, total),
      ]),
    );
  }

  Widget _distRow(AppTones t, int star, int count, int total) {
    final frac = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(
          width: 14,
          child: Text('$star',
              style: TextStyle(color: t.textSecondary, fontSize: 12)),
        ),
        const Icon(Icons.star, size: 12, color: Color(0xFFE3B041)),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 7,
              backgroundColor: t.surfaceAlt,
              valueColor:
                  const AlwaysStoppedAnimation(Color(0xFFE3B041)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 22,
          child: Text('$count',
              textAlign: TextAlign.right,
              style: TextStyle(color: t.textMuted, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _complaintsCard(BuildContext context, AppTones t, WidgetRef ref,
      List<Review> complaints, int open) {
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
            child: Row(children: [
              Text('Complaint Log',
                  style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              if (open > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text('$open open',
                      style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 11)),
                ),
            ]),
          ),
          Divider(height: 1, color: t.border),
          if (complaints.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                  child: Text('No complaints logged',
                      style: TextStyle(color: t.textMuted, fontSize: 13))),
            )
          else
            for (final r in complaints) _complaintRow(context, t, ref, r),
        ],
      ),
    );
  }

  Widget _complaintRow(
      BuildContext context, AppTones t, WidgetRef ref, Review r) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: t.border))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.report_problem_outlined,
            size: 18,
            color: r.resolved ? AppColors.success : AppColors.error),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${r.customer} · ${r.channel}',
                style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            Text(r.comment,
                style: TextStyle(color: t.textSecondary, fontSize: 12)),
          ]),
        ),
        const SizedBox(width: 10),
        r.resolved
            ? const Text('Resolved',
                style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 12))
            : SizedBox(
                height: 30,
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(reviewsProvider.notifier).resolve(r.id);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Complaint from ${r.customer} resolved'),
                      duration: const Duration(milliseconds: 900),
                      backgroundColor: AppColors.success,
                    ));
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.accent),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Resolve',
                      style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5)),
                ),
              ),
      ]),
    );
  }

  Widget _reviewCard(AppTones t, Review r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: t.surfaceAlt,
          child: Text(r.customer[0],
              style: TextStyle(
                  color: t.textSecondary, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(r.customer,
                  style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5)),
              const SizedBox(width: 8),
              for (int i = 1; i <= 5; i++)
                Icon(i <= r.rating ? Icons.star : Icons.star_border,
                    size: 13, color: const Color(0xFFE3B041)),
              const Spacer(),
              Text('${r.channel} · ${r.daysAgo == 0 ? 'today' : '${r.daysAgo}d ago'}',
                  style: TextStyle(color: t.textMuted, fontSize: 11)),
            ]),
            const SizedBox(height: 4),
            Text(r.comment,
                style: TextStyle(color: t.textSecondary, fontSize: 12.5)),
          ]),
        ),
      ]),
    );
  }
}
