import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../providers/recipe_provider.dart';

/// SCREENS 33–35 — Recipe Costing & Yield. Expandable rows breaking down
/// ingredient cost allocation (g/ml), rolling up to food-cost %, margin, profit
/// and a system-recommended retail price for the target food-cost threshold.
class RecipeCostingScreen extends ConsumerStatefulWidget {
  const RecipeCostingScreen({super.key});

  @override
  ConsumerState<RecipeCostingScreen> createState() =>
      _RecipeCostingScreenState();
}

class _RecipeCostingScreenState extends ConsumerState<RecipeCostingScreen> {
  final Set<String> _expanded = {};

  static String _m(double v) => '\$${v.toStringAsFixed(2)}';
  static String _pct(double v) => '${(v * 100).toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    final t = AppTones(ref.watch(themeProvider));
    final recipes = ref.watch(recipesProvider);
    final target = ref.watch(targetFoodCostProvider);

    return Container(
      color: t.canvas,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recipe Costing & Yield',
                        style: TextStyle(
                            color: t.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    Text('Ingredient cost allocation, margins and recommended pricing.',
                        style: TextStyle(color: t.textMuted, fontSize: 13)),
                  ],
                ),
                const Spacer(),
                _targetControl(t, target),
              ],
            ),
            const SizedBox(height: 18),
            _headerRow(t),
            const SizedBox(height: 8),
            for (final r in recipes) _recipeCard(t, r, target),
          ],
        ),
      ),
    );
  }

  Widget _targetControl(AppTones t, double target) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          Text('Target food cost',
              style: TextStyle(color: t.textSecondary, fontSize: 12.5)),
          const SizedBox(width: 12),
          _step(t, Icons.remove, () {
            final v = (target - 0.01).clamp(0.15, 0.6);
            ref.read(targetFoodCostProvider.notifier).state = v;
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(_pct(target),
                style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 16)),
          ),
          _step(t, Icons.add, () {
            final v = (target + 0.01).clamp(0.15, 0.6);
            ref.read(targetFoodCostProvider.notifier).state = v;
          }),
        ],
      ),
    );
  }

  Widget _step(AppTones t, IconData icon, VoidCallback onTap) {
    return Material(
      color: t.surfaceAlt,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: t.border),
          ),
          child: Icon(icon, size: 16, color: t.textPrimary),
        ),
      ),
    );
  }

  Widget _headerRow(AppTones t) {
    Widget h(String s, int flex) => Expanded(
        flex: flex,
        child: Text(s,
            style: TextStyle(
                color: t.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700)));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const SizedBox(width: 28),
          h('RECIPE', 4),
          h('COST / PORTION', 2),
          h('FOOD COST', 2),
          h('MARGIN', 2),
          h('PRICE', 2),
          h('RECOMMENDED', 2),
        ],
      ),
    );
  }

  Widget _recipeCard(AppTones t, Recipe r, double target) {
    final open = _expanded.contains(r.id);
    final overTarget = r.foodCostPct > target;
    final fcColor = overTarget ? AppColors.error : AppColors.success;
    final recommended = r.recommendedPrice(target);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: open ? AppColors.accent.withValues(alpha: 0.5) : t.border),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() =>
                open ? _expanded.remove(r.id) : _expanded.add(r.id)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(open ? Icons.expand_less : Icons.expand_more,
                      size: 20, color: t.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name,
                            style: TextStyle(
                                color: t.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5)),
                        Text('${r.category} · yields ${r.yieldPortions} · ${r.ingredients.length} ingredients',
                            style: TextStyle(
                                color: t.textMuted, fontSize: 11.5)),
                      ],
                    ),
                  ),
                  _cell(t, _m(r.costPerPortion), 2),
                  Expanded(
                    flex: 2,
                    child: Text(_pct(r.foodCostPct),
                        style: TextStyle(
                            color: fcColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5)),
                  ),
                  _cell(t, _pct(r.marginPct), 2, color: AppColors.success),
                  _cell(t, _m(r.sellingPrice), 2),
                  Expanded(
                    flex: 2,
                    child: Text(_m(recommended),
                        style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5)),
                  ),
                ],
              ),
            ),
          ),
          if (open) _breakdown(t, r, target, recommended, overTarget),
        ],
      ),
    );
  }

  Widget _cell(AppTones t, String s, int flex, {Color? color}) => Expanded(
        flex: flex,
        child: Text(s,
            style: TextStyle(
                color: color ?? t.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13.5)),
      );

  Widget _breakdown(AppTones t, Recipe r, double target, double recommended,
      bool overTarget) {
    return Container(
      decoration: BoxDecoration(
        color: t.surfaceAlt.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(7)),
        border: Border(top: BorderSide(color: t.border)),
      ),
      padding: const EdgeInsets.fromLTRB(36, 14, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('INGREDIENT COST ALLOCATION',
              style: TextStyle(
                  color: t.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0)),
          const SizedBox(height: 10),
          for (final ing in r.ingredients)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(ing.name,
                        style: TextStyle(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(ing.quantityLabel,
                        style: TextStyle(color: t.textSecondary, fontSize: 12.5)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('@ ${_m(ing.costPerUnit)}/${ing.unit}',
                        style: TextStyle(color: t.textMuted, fontSize: 12)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(_m(ing.lineCost),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                ],
              ),
            ),
          Divider(height: 18, color: t.border),
          // Roll-up tiles.
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _tile(t, 'Batch Cost', _m(r.batchCost), t.textPrimary),
              _tile(t, 'Cost / Portion', _m(r.costPerPortion), t.textPrimary),
              _tile(t, 'Food Cost %', _pct(r.foodCostPct),
                  overTarget ? AppColors.error : AppColors.success),
              _tile(t, 'Gross Margin', _pct(r.marginPct), AppColors.success),
              _tile(t, 'Profit / Portion', _m(r.profit), AppColors.accent),
              _tile(t, 'Recommended @ ${_pct(target)}', _m(recommended),
                  AppColors.accent),
            ],
          ),
          if (overTarget) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline,
                      size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        'Food cost ${_pct(r.foodCostPct)} exceeds target ${_pct(target)} — raise price toward ${_m(recommended)} to protect margin.',
                        style: TextStyle(
                            color: t.textSecondary, fontSize: 12.5)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tile(AppTones t, String label, String value, Color color) {
    return Container(
      width: 168,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: t.textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w900, fontSize: 17)),
        ],
      ),
    );
  }
}
