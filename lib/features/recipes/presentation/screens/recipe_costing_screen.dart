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

  static String _m(double v) => 'PKR ${v.toStringAsFixed(2)}';
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
                SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _showNewRecipe,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Recipe',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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

  Future<void> _showNewRecipe() async {
    final t = AppTones(ref.read(themeProvider));
    final name = TextEditingController();
    final price = TextEditingController();
    final yieldC = TextEditingController(text: '1');
    String category = 'Mains';
    const cats = ['Mains', 'Starters', 'Sides', 'Desserts', 'Bar'];
    final ingredients = <RecipeIngredient>[];
    // New-ingredient draft controllers.
    final ingName = TextEditingController();
    final ingQty = TextEditingController();
    final ingUnit = TextEditingController(text: 'g');
    final ingCost = TextEditingController();
    String? error;

    InputDecoration dec(String h) => InputDecoration(
          isDense: true,
          hintText: h,
          hintStyle: TextStyle(color: t.textMuted, fontSize: 13),
          filled: true,
          fillColor: t.surfaceAlt,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: t.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
          ),
        );

    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => StatefulBuilder(builder: (context, setLocal) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 660),
            child: Container(
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: t.border),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                  decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: t.border))),
                  child: Row(children: [
                    Text('New Recipe',
                        style: TextStyle(
                            color: t.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, size: 20, color: t.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ]),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                            controller: name,
                            style: TextStyle(color: t.textPrimary),
                            decoration: dec('Recipe name')),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(
                            child: Container(
                              height: 44,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: t.surfaceAlt,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: t.border),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: category,
                                  dropdownColor: t.surface,
                                  style: TextStyle(
                                      color: t.textPrimary, fontSize: 14),
                                  items: cats
                                      .map((c) => DropdownMenuItem(
                                          value: c, child: Text(c)))
                                      .toList(),
                                  onChanged: (v) =>
                                      setLocal(() => category = v ?? category),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                                controller: price,
                                keyboardType: const TextInputType
                                    .numberWithOptions(decimal: true),
                                style: TextStyle(color: t.textPrimary),
                                decoration: dec('Selling price')),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 90,
                            child: TextField(
                                controller: yieldC,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: t.textPrimary),
                                decoration: dec('Yield')),
                          ),
                        ]),
                        const SizedBox(height: 16),
                        Text('INGREDIENTS',
                            style: TextStyle(
                                color: t.textMuted,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8)),
                        const SizedBox(height: 8),
                        for (int i = 0; i < ingredients.length; i++)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: t.surfaceAlt,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: t.border),
                            ),
                            child: Row(children: [
                              Expanded(
                                child: Text(ingredients[i].name,
                                    style: TextStyle(
                                        color: t.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              ),
                              Text(
                                  '${ingredients[i].quantityLabel} · cost ${_m(ingredients[i].lineCost)}',
                                  style: TextStyle(
                                      color: t.textMuted, fontSize: 11.5)),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => setLocal(
                                    () => ingredients.removeAt(i)),
                                child: Icon(Icons.close,
                                    size: 15,
                                    color: AppColors.error
                                        .withValues(alpha: 0.8)),
                              ),
                            ]),
                          ),
                        const SizedBox(height: 6),
                        // Draft ingredient input row.
                        Row(children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                                controller: ingName,
                                style: TextStyle(
                                    color: t.textPrimary, fontSize: 13),
                                decoration: dec('Ingredient')),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                                controller: ingQty,
                                keyboardType: const TextInputType
                                    .numberWithOptions(decimal: true),
                                style: TextStyle(
                                    color: t.textPrimary, fontSize: 13),
                                decoration: dec('Qty')),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 56,
                            child: TextField(
                                controller: ingUnit,
                                style: TextStyle(
                                    color: t.textPrimary, fontSize: 13),
                                decoration: dec('unit')),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                                controller: ingCost,
                                keyboardType: const TextInputType
                                    .numberWithOptions(decimal: true),
                                style: TextStyle(
                                    color: t.textPrimary, fontSize: 13),
                                decoration: dec('cost/unit')),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            height: 42,
                            child: ElevatedButton(
                              onPressed: () {
                                final n = ingName.text.trim();
                                final q =
                                    double.tryParse(ingQty.text.trim());
                                final c =
                                    double.tryParse(ingCost.text.trim());
                                if (n.isEmpty || q == null || c == null) {
                                  return;
                                }
                                setLocal(() {
                                  ingredients.add(RecipeIngredient(
                                      name: n,
                                      quantity: q,
                                      unit: ingUnit.text.trim().isEmpty
                                          ? 'g'
                                          : ingUnit.text.trim(),
                                      costPerUnit: c));
                                  ingName.clear();
                                  ingQty.clear();
                                  ingCost.clear();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: t.surfaceAlt,
                                foregroundColor: t.textPrimary,
                                elevation: 0,
                                side: BorderSide(color: t.border),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Icon(Icons.add, size: 18),
                            ),
                          ),
                        ]),
                        if (error != null) ...[
                          const SizedBox(height: 10),
                          Text(error!,
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 12.5)),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: t.border))),
                  child: Row(children: [
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child:
                          Text('Cancel', style: TextStyle(color: t.textMuted)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final n = name.text.trim();
                        final p = double.tryParse(price.text.trim());
                        if (n.isEmpty) {
                          setLocal(() => error = 'Recipe name is required');
                          return;
                        }
                        if (p == null || p <= 0) {
                          setLocal(() => error = 'Enter a valid selling price');
                          return;
                        }
                        if (ingredients.isEmpty) {
                          setLocal(() => error = 'Add at least one ingredient');
                          return;
                        }
                        ref.read(recipesProvider.notifier).create(
                              name: n,
                              category: category,
                              yieldPortions:
                                  int.tryParse(yieldC.text.trim()) ?? 1,
                              sellingPrice: p,
                              ingredients: List.of(ingredients),
                            );
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Create Recipe',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        );
      }),
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
                  SizedBox(
                    width: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: 'Delete recipe',
                      icon: Icon(Icons.delete_outline,
                          size: 18,
                          color: AppColors.error.withValues(alpha: 0.8)),
                      onPressed: () {
                        ref.read(recipesProvider.notifier).remove(r.id);
                        _expanded.remove(r.id);
                      },
                    ),
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
