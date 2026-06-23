import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../domain/models/menu_item_model.dart';
import '../providers/menu_provider.dart';

/// SCREENS 22–26 — Menu Management. Master-detail catalogue: categories (left),
/// product cards with stock state + edit/delete (centre), and a create/edit
/// form capturing pricing, status, variations (Small/Medium/Large) and add-ons
/// (right). Edits flow live into the shared menu catalogue used by the POS.
class MenuEditorScreen extends ConsumerStatefulWidget {
  const MenuEditorScreen({super.key});

  @override
  ConsumerState<MenuEditorScreen> createState() => _MenuEditorScreenState();
}

const List<String> _kVariationOptions = ['Small', 'Medium', 'Large'];
const List<String> _kAddOnOptions = [
  'Extra Cheese',
  'Extra Sauce',
  'Spicy',
  'No Onion',
  'Gluten-Free',
];

class _MenuEditorScreenState extends ConsumerState<MenuEditorScreen> {
  String _category = 'Mains';

  // Editor panel state. _editingId == null && _panelOpen => create mode.
  bool _panelOpen = false;
  String? _editingId;

  final _name = TextEditingController();
  final _price = TextEditingController();
  final _sku = TextEditingController();
  final _desc = TextEditingController();
  final _image = TextEditingController();
  bool _available = true;
  String _formCategory = 'Mains';
  final Set<String> _variations = {};
  final Set<String> _addOns = {};
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _sku.dispose();
    _desc.dispose();
    _image.dispose();
    super.dispose();
  }

  void _startCreate() {
    setState(() {
      _editingId = null;
      _panelOpen = true;
      _error = null;
      _name.clear();
      _price.clear();
      _sku.clear();
      _desc.clear();
      _image.clear();
      _available = true;
      _formCategory = _category;
      _variations.clear();
      _addOns.clear();
    });
  }

  void _loadItem(MenuItemModel item) {
    setState(() {
      _editingId = item.id;
      _panelOpen = true;
      _error = null;
      _name.text = item.name;
      _price.text = item.price.toStringAsFixed(2);
      _sku.text = item.sku;
      _desc.text = item.description;
      _image.text = item.image;
      _available = item.available;
      _formCategory = item.category;
      _variations
        ..clear()
        ..addAll(item.variations);
      _addOns
        ..clear()
        ..addAll(item.addOns);
    });
  }

  void _save() {
    setState(() => _error = null);
    final name = _name.text.trim();
    final price = double.tryParse(_price.text.trim());
    if (name.isEmpty) {
      setState(() => _error = 'Item name is required');
      return;
    }
    if (price == null || price < 0) {
      setState(() => _error = 'Enter a valid price');
      return;
    }
    final notifier = ref.read(menuProvider.notifier);
    if (_editingId == null) {
      notifier.createItem(
        name: name,
        description: _desc.text.trim(),
        price: price,
        category: _formCategory,
        sku: _sku.text.trim(),
        image: _image.text.trim(),
        available: _available,
        variations: _variations.toList(),
        addOns: _addOns.toList(),
      );
    } else {
      final existing = ref
          .read(menuProvider)
          .firstWhere((e) => e.id == _editingId);
      notifier.updateItem(existing.copyWith(
        name: name,
        description: _desc.text.trim(),
        price: price,
        category: _formCategory,
        sku: _sku.text.trim(),
        image: _image.text.trim().isEmpty ? existing.image : _image.text.trim(),
        available: _available,
        variations: _variations.toList(),
        addOns: _addOns.toList(),
      ));
    }
    setState(() {
      _category = _formCategory;
      _panelOpen = false;
      _editingId = null;
    });
    _toast(_editingId == null ? 'Item saved' : 'Item updated');
  }

  void _delete() {
    if (_editingId == null) return;
    ref.read(menuProvider.notifier).deleteItem(_editingId!);
    setState(() {
      _panelOpen = false;
      _editingId = null;
    });
    _toast('Item deleted');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(milliseconds: 1000),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTones(ref.watch(themeProvider));
    return Container(
      color: t.canvas,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 240, child: _categoriesPane(t)),
          Container(width: 1, color: t.border),
          Expanded(child: _productsPane(t)),
          if (_panelOpen) ...[
            Container(width: 1, color: t.border),
            SizedBox(width: 372, child: _editorPane(t)),
          ],
        ],
      ),
    );
  }

  // --- Categories (left) -----------------------------------------------------
  Widget _categoriesPane(AppTones t) {
    final cats = ref.watch(editorCategoriesProvider);
    final counts = ref.watch(categoryCountsProvider);
    return Container(
      color: t.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 14, 12),
            child: Row(
              children: [
                Text('Categories',
                    style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const Spacer(),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, size: 18, color: Colors.white),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: t.border),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final c in cats)
                  _categoryRow(t, c, counts[c] ?? 0, c == _category),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryRow(AppTones t, String name, int count, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => _category = name),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withValues(alpha: 0.14) : t.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? AppColors.accent : t.border),
        ),
        child: Row(
          children: [
            Icon(Icons.drag_indicator, size: 16, color: t.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(name,
                  style: TextStyle(
                      color: selected ? t.textPrimary : t.textSecondary,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 14)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: selected ? AppColors.accent : t.border,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('$count',
                  style: TextStyle(
                      color: selected ? Colors.white : t.textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12)),
            ),
            const SizedBox(width: 6),
            Icon(Icons.visibility_outlined, size: 16, color: t.textMuted),
          ],
        ),
      ),
    );
  }

  // --- Products (centre) -----------------------------------------------------
  Widget _productsPane(AppTones t) {
    final items =
        ref.watch(menuProvider).where((i) => i.category == _category).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Row(
            children: [
              Text(_category,
                  style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Text('(${items.length} Items)',
                  style: TextStyle(color: t.textMuted, fontSize: 13)),
              const Spacer(),
              _ghostButton(t, 'Bulk Edit', Icons.edit_note,
                  () => _toast('Bulk edit (demo)')),
              const SizedBox(width: 10),
              _goldButton('Publish Changes', Icons.publish,
                  () => _toast('Changes published')),
            ],
          ),
        ),
        Divider(height: 1, color: t.border),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final item in items) _productCard(t, item),
                _addNewCard(t),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _productCard(AppTones t, MenuItemModel item) {
    final selected = _editingId == item.id;
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: selected ? AppColors.accent : t.border,
            width: selected ? 1.6 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(7)),
                child: SizedBox(
                  height: 130,
                  width: double.infinity,
                  child: ColorFiltered(
                    colorFilter: item.available
                        ? const ColorFilter.mode(
                            Colors.transparent, BlendMode.multiply)
                        : const ColorFilter.matrix(<double>[
                            0.33, 0.33, 0.33, 0, 0, //
                            0.33, 0.33, 0.33, 0, 0, //
                            0.33, 0.33, 0.33, 0, 0, //
                            0, 0, 0, 1, 0,
                          ]),
                    child: Image.network(item.image, fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                              color: t.surfaceAlt,
                              child: Icon(Icons.restaurant,
                                  color: t.textMuted),
                            )),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: _stockBadge(item.available),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Row(children: [
                  Text('PKR ${item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  if (item.hasHappyHour) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                          'PKR ${item.happyHourPrice!.toStringAsFixed(0)} · ${item.happyHourLabel}',
                          style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                              fontSize: 9.5)),
                    ),
                  ],
                ]),
                const SizedBox(height: 10),
                Divider(height: 1, color: t.border),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('SKU: ${item.sku.isEmpty ? '—' : item.sku}',
                        style: TextStyle(color: t.textMuted, fontSize: 11)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _loadItem(item),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.edit,
                            size: 14, color: AppColors.accent),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _HappyHourDialog.show(context, ref, item),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: item.hasHappyHour
                              ? AppColors.success.withValues(alpha: 0.16)
                              : t.surfaceAlt,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.schedule,
                            size: 14,
                            color: item.hasHappyHour
                                ? AppColors.success
                                : t.textMuted),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () =>
                          ref.read(menuProvider.notifier).deleteItem(item.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.delete_outline,
                            size: 14,
                            color: AppColors.error.withValues(alpha: 0.9)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockBadge(bool available) {
    final color = available ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: available ? Colors.white : color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(available ? Icons.circle : Icons.block,
              size: 9, color: available ? color : Colors.white),
          const SizedBox(width: 5),
          Text(available ? 'In Stock' : 'Sold Out',
              style: TextStyle(
                  color: available ? const Color(0xFF111111) : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5)),
        ],
      ),
    );
  }

  Widget _addNewCard(AppTones t) {
    return GestureDetector(
      onTap: _startCreate,
      child: Container(
        width: 240,
        height: 222,
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.5),
              width: 1.4,
              style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: t.surface,
                shape: BoxShape.circle,
                border: Border.all(color: t.border),
              ),
              child: const Icon(Icons.add, size: 26, color: AppColors.accent),
            ),
            const SizedBox(height: 12),
            Text('Add New Item',
                style: TextStyle(
                    color: t.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // --- Editor (right) --------------------------------------------------------
  Widget _editorPane(AppTones t) {
    final editorCats = ref.watch(editorCategoriesProvider);
    return Container(
      color: t.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              children: [
                Text(_editingId == null ? 'Create Item' : 'Edit Item',
                    style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: t.textMuted),
                  onPressed: () => setState(() => _panelOpen = false),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: t.border),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _statusToggle(t),
                  const SizedBox(height: 18),
                  _sectionLabel(t, 'BASIC INFO'),
                  _fieldLabel(t, 'Item Name'),
                  _input(t, _name, 'e.g. Prime Ribeye Steak'),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel(t, 'Price (PKR )'),
                            _input(t, _price, '0.00',
                                keyboard: const TextInputType.numberWithOptions(
                                    decimal: true)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel(t, 'SKU'),
                            _input(t, _sku, 'MEAT-001'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _fieldLabel(t, 'Description'),
                  _input(t, _desc, 'Short description…', maxLines: 3),
                  const SizedBox(height: 18),
                  _sectionLabel(t, 'MEDIA'),
                  _fieldLabel(t, 'Image URL'),
                  _input(t, _image, 'https://…'),
                  const SizedBox(height: 18),
                  _sectionLabel(t, 'ORGANIZATION & MODIFIERS'),
                  _fieldLabel(t, 'Primary Category'),
                  _categoryDropdown(t, editorCats),
                  const SizedBox(height: 14),
                  _fieldLabel(t, 'Variations'),
                  _checkboxRow(t, _kVariationOptions, _variations),
                  const SizedBox(height: 14),
                  _fieldLabel(t, 'Add-ons'),
                  _checkboxRow(t, _kAddOnOptions, _addOns),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 15, color: AppColors.error),
                        const SizedBox(width: 6),
                        Text(_error!,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 12.5)),
                      ],
                    ),
                  ],
                  if (_editingId != null) ...[
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: _delete,
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline,
                              size: 16, color: AppColors.error),
                          const SizedBox(width: 6),
                          const Text('Delete item',
                              style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Divider(height: 1, color: t.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _ghostButton(t, 'Cancel', Icons.close,
                      () => setState(() => _panelOpen = false)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Save Changes',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusToggle(AppTones t) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Item Status',
                    style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                    _available
                        ? 'Currently available for ordering'
                        : 'Marked Sold Out',
                    style: TextStyle(color: t.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: _available,
            activeThumbColor: AppColors.accent,
            onChanged: (v) => setState(() => _available = v),
          ),
        ],
      ),
    );
  }

  Widget _categoryDropdown(AppTones t, List<String> cats) {
    final value = cats.contains(_formCategory) ? _formCategory : cats.first;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          dropdownColor: t.surface,
          icon: Icon(Icons.expand_more, color: t.textMuted),
          style: TextStyle(color: t.textPrimary, fontSize: 14),
          items: [
            for (final c in cats)
              DropdownMenuItem<String>(value: c, child: Text(c)),
          ],
          onChanged: (v) => setState(() => _formCategory = v ?? value),
        ),
      ),
    );
  }

  Widget _checkboxRow(AppTones t, List<String> options, Set<String> selected) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          GestureDetector(
            onTap: () => setState(() {
              if (!selected.add(o)) selected.remove(o);
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: selected.contains(o)
                    ? AppColors.accent.withValues(alpha: 0.14)
                    : t.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: selected.contains(o) ? AppColors.accent : t.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected.contains(o)
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 16,
                    color: selected.contains(o)
                        ? AppColors.accent
                        : t.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(o,
                      style: TextStyle(
                          color: selected.contains(o)
                              ? t.textPrimary
                              : t.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // --- Shared bits -----------------------------------------------------------
  Widget _sectionLabel(AppTones t, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: TextStyle(
                color: t.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1)),
      );

  Widget _fieldLabel(AppTones t, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: TextStyle(
                color: t.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600)),
      );

  Widget _input(AppTones t, TextEditingController c, String hint,
      {int maxLines = 1, TextInputType? keyboard}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: TextStyle(color: t.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: TextStyle(color: t.textMuted, fontSize: 13.5),
        filled: true,
        fillColor: t.surfaceAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: t.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
    );
  }

  Widget _ghostButton(AppTones t, String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: t.textSecondary),
        label: Text(label,
            style: TextStyle(
                color: t.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13.5)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: t.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _goldButton(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

// =============================================================================
// HAPPY HOUR (TIME-BASED PRICING) DIALOG — SRS 5.x
// =============================================================================

class _HappyHourDialog extends ConsumerStatefulWidget {
  const _HappyHourDialog(this.item);
  final MenuItemModel item;

  static Future<void> show(
          BuildContext context, WidgetRef ref, MenuItemModel item) =>
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.55),
        builder: (_) => _HappyHourDialog(item),
      );

  @override
  ConsumerState<_HappyHourDialog> createState() => _HappyHourDialogState();
}

class _HappyHourDialogState extends ConsumerState<_HappyHourDialog> {
  late final TextEditingController _price;
  late int _start;
  late int _end;
  String? _error;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _price = TextEditingController(
        text: i.happyHourPrice == null
            ? ''
            : i.happyHourPrice!.toStringAsFixed(0));
    _start = i.happyHourStart ?? 16;
    _end = i.happyHourEnd ?? 18;
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  void _save() {
    final p = double.tryParse(_price.text.trim());
    if (p == null || p <= 0) {
      setState(() => _error = 'Enter a valid happy-hour price');
      return;
    }
    if (p >= widget.item.price) {
      setState(() => _error = 'Happy-hour price must be below the base price');
      return;
    }
    if (_start == _end) {
      setState(() => _error = 'Start and end hour cannot be the same');
      return;
    }
    ref.read(menuProvider.notifier).setHappyHour(widget.item.id,
        price: p, startHour: _start, endHour: _end);
    Navigator.of(context).pop();
  }

  void _remove() {
    ref.read(menuProvider.notifier).setHappyHour(widget.item.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTones(ref.watch(themeProvider));
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: t.border))),
                child: Row(children: [
                  const Icon(Icons.schedule,
                      size: 20, color: AppColors.success),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Happy Hour Pricing',
                            style: TextStyle(
                                color: t.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w800)),
                        Text(widget.item.name,
                            style:
                                TextStyle(color: t.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: t.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Base price: PKR ${widget.item.price.toStringAsFixed(2)}',
                        style: TextStyle(
                            color: t.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _price,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: t.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Discounted price',
                        hintStyle: TextStyle(color: t.textMuted),
                        prefixIcon: Icon(Icons.attach_money,
                            size: 18, color: t.textMuted),
                        filled: true,
                        fillColor: t.surfaceAlt,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: t.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: AppColors.accent, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: _hourPicker(t, 'From', _start, (v) {
                        setState(() => _start = v);
                      })),
                      const SizedBox(width: 12),
                      Expanded(child: _hourPicker(t, 'To', _end, (v) {
                        setState(() => _end = v);
                      })),
                    ]),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        const Icon(Icons.error_outline,
                            size: 15, color: AppColors.error),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 12.5)),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: t.border))),
                child: Row(children: [
                  if (widget.item.hasHappyHour)
                    TextButton.icon(
                      onPressed: _remove,
                      icon: const Icon(Icons.delete_outline,
                          size: 16, color: AppColors.error),
                      label: const Text('Remove',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  const Spacer(),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Save Schedule',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hourPicker(
      AppTones t, String label, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: t.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: t.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: value,
              dropdownColor: t.surface,
              icon: Icon(Icons.expand_more, color: t.textMuted),
              style: TextStyle(color: t.textPrimary, fontSize: 14),
              items: [
                for (int h = 0; h < 24; h++)
                  DropdownMenuItem(
                      value: h,
                      child: Text('${h.toString().padLeft(2, '0')}:00')),
              ],
              onChanged: (v) => onChanged(v ?? value),
            ),
          ),
        ),
      ],
    );
  }
}
