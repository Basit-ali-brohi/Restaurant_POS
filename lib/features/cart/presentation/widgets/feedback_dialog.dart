import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../table_management/presentation/providers/table_provider.dart';

class FeedbackDialog extends ConsumerStatefulWidget {
  final VoidCallback onSubmit;

  const FeedbackDialog({super.key, required this.onSubmit});

  @override
  ConsumerState<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends ConsumerState<FeedbackDialog> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    // Force dark mode style for the gold/obsidian theme look or adapt to system
    final isDarkMode = true; // User requested "Obsidian & Gold" theme explicitly

    return Center(
      child: GlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.all(24),
        color: Colors.black.withOpacity(0.9), // Obsidian-like
        width: 350,
        border: Border.all(color: AppColors.accent.withOpacity(0.5), width: 1),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars, color: AppColors.accent, size: 48),
              const SizedBox(height: 16),
              const Text(
                "Rate Your Experience",
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "How was our service?",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () => setState(() => _rating = index + 1),
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: AppColors.accent, // Gold
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                     // In a real app, save feedback here
                     widget.onSubmit();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "Submit",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
