import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../domain/models/menu_item_model.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../../../inventory/domain/models/inventory_item_model.dart';

class MenuItemWidget extends ConsumerStatefulWidget {
  final MenuItemModel item;
  final VoidCallback onTap;
  final GlobalKey? globalKey; // Key for hero animation source

  const MenuItemWidget({
    super.key,
    required this.item,
    required this.onTap,
    this.globalKey,
  });

  @override
  ConsumerState<MenuItemWidget> createState() => _MenuItemWidgetState();
}

class _MenuItemWidgetState extends ConsumerState<MenuItemWidget> {
  bool _isHovered = false;
  bool _isAdded = false;

  void _onTap() async {
    setState(() => _isAdded = true);
    HapticFeedback.lightImpact();
    widget.onTap();
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) setState(() => _isAdded = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final inventory = ref.watch(inventoryProvider);
    final normalizedName = widget.item.name.trim().toLowerCase();
    final match = inventory.where((e) => e.name.trim().toLowerCase() == normalizedName).toList();
    final bool isOutOfStock = match.isNotEmpty ? (match.first.quantity <= 0) : false;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          if (isOutOfStock) {
            HapticFeedback.mediumImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Item out of stock")),
            );
            return;
          }
          _onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
          child: GlassContainer(
            borderRadius: 20, // Rounded corners as requested
            // Subtle Gradient from top-left
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode ? [
                Colors.white.withOpacity(_isHovered ? 0.15 : 0.1),
                Colors.white.withOpacity(_isHovered ? 0.05 : 0.02),
              ] : [
                Colors.black.withOpacity(_isHovered ? 0.08 : 0.05),
                Colors.black.withOpacity(_isHovered ? 0.03 : 0.01),
              ],
            ),
            blur: 15,
            border: Border.all(
              color: isDarkMode 
                  ? Colors.white.withOpacity(_isHovered ? 0.2 : 0.1)
                  : Colors.black.withOpacity(_isHovered ? 0.1 : 0.05),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
              if (_isHovered)
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'menu_image_${widget.item.id}',
                        child: ClipRRect(
                          key: widget.globalKey,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: Image.network(
                            widget.item.image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: isDarkMode ? Colors.grey[900] : Colors.grey[300],
                                child: Center(
                                  child: Icon(Icons.restaurant, 
                                    color: isDarkMode ? Colors.white24 : Colors.black26, 
                                    size: 40
                                  ),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: isDarkMode ? Colors.grey[900] : Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.accent,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      if (isOutOfStock)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(isDarkMode ? 0.45 : 0.35),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            child: Center(
                              child: GlassContainer(
                                borderRadius: 999,
                                color: Colors.redAccent.withOpacity(0.2),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                border: Border.all(color: Colors.redAccent.withOpacity(0.6)),
                                child: const Text(
                                  "Out of Stock",
                                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ),
                      
                      // Glassmorphic Price Tag
                      Positioned(
                        top: 10,
                        right: 10,
                        child: GlassContainer(
                          borderRadius: 12,
                          color: isDarkMode ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.8),
                          blur: 10,
                          border: Border.all(
                            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Text(
                            "\$${widget.item.price.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Details
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.item.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isOutOfStock
                                ? (isDarkMode ? Colors.white24 : Colors.black12)
                                : (_isAdded 
                                    ? (isDarkMode ? Colors.white : Colors.black) 
                                    : AppColors.accent.withOpacity(0.2)),
                            shape: BoxShape.circle,
                            boxShadow: _isAdded
                                ? [
                                    BoxShadow(
                                      color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.6),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : [],
                          ),
                          child: Icon(
                            Icons.add,
                            color: isOutOfStock ? (isDarkMode ? Colors.white38 : Colors.black26) : (_isAdded ? AppColors.accent : AppColors.accent),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
