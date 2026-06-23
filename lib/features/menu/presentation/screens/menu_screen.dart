import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart'; // Add this import
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../cart/presentation/widgets/cart_sidebar.dart';
import '../../domain/models/menu_item_model.dart'; // Add this import
import '../providers/menu_provider.dart';
import '../widgets/menu_item_widget.dart';

import '../../../../core/providers/theme_provider.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  final Map<String, GlobalKey> _itemKeys = {};
  final GlobalKey _cartKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';

  GlobalKey _getItemKey(String id) {
    if (!_itemKeys.containsKey(id)) {
      _itemKeys[id] = GlobalKey();
    }
    return _itemKeys[id]!;
  }

  void _runFlyAnimation(GlobalKey startKey, MenuItemModel item) {
    final RenderBox? startBox = startKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? targetBox = _cartKey.currentContext?.findRenderObject() as RenderBox?;

    if (startBox == null || targetBox == null) {
      ref.read(cartProvider.notifier).addItem(item);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${item.name} added to cart"),
          duration: const Duration(milliseconds: 500),
          backgroundColor: AppColors.success,
        ),
      );
      return;
    }

    final startPosition = startBox.localToGlobal(Offset.zero);
    final targetPosition = targetBox.localToGlobal(Offset.zero);
    
    // Target center of the cart sidebar or a specific point (e.g., top right)
    final endPosition = Offset(
      targetPosition.dx + targetBox.size.width / 2,
      targetPosition.dy + targetBox.size.height / 2,
    );

    OverlayEntry? entry;
    
    entry = OverlayEntry(
      builder: (_) {
        return _FlyAnimationWidget(
          startPosition: startPosition,
          endPosition: endPosition,
          item: item,
          onComplete: () {
            entry?.remove();
            if (!mounted) return;
            ref.read(cartProvider.notifier).addItem(item);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("${item.name} added to cart"),
                duration: const Duration(milliseconds: 500),
                backgroundColor: AppColors.success,
              ),
            );
          },
        );
      },
    );

    Overlay.of(context).insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final allItems = ref.watch(menuProvider);
    final categories = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final isDarkMode = ref.watch(themeProvider);
    final query = _searchQuery.trim().toLowerCase();

    final List<MenuItemModel> byCategory = selectedCategory == 'All'
        ? allItems
        : allItems.where((item) => item.category == selectedCategory).toList();

    final List<MenuItemModel> menuItems = query.isEmpty
        ? byCategory
        : byCategory.where((item) {
            return item.name.toLowerCase().contains(query) ||
                item.description.toLowerCase().contains(query);
          }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 900;
        int crossAxisCount = 2;
        double childAspectRatio = 0.8;
        
        if (constraints.maxWidth < 600) {
          crossAxisCount = 2;
          childAspectRatio = 0.72; // Taller cards for mobile
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 3;
        }
        if (constraints.maxWidth > 1100) crossAxisCount = 4;
        if (constraints.maxWidth > 1400) crossAxisCount = 5;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.transparent,
          endDrawer: isSmallScreen
              ? Drawer(
                  width: 320,
                  child: const CartSidebar(),
                )
              : null,
          floatingActionButton: isSmallScreen
              ? FloatingActionButton(
                  key: _cartKey, // Target for animation on small screens
                  onPressed: () {
                    _scaffoldKey.currentState?.openEndDrawer();
                  },
                  backgroundColor: AppColors.accent,
                  child: const Icon(Icons.shopping_cart, color: Colors.white),
                )
              : null,
          body: Row(
            children: [
              // Menu Area
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    // Header & Search
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: constraints.maxWidth < 600 
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FadeInLeft(
                                duration: const Duration(milliseconds: 600),
                                child: Text(
                                  "Menu",
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              FadeInDown(
                                duration: const Duration(milliseconds: 600),
                                child: GlassContainer(
                                  width: double.infinity,
                                  height: 50,
                                  borderRadius: 12,
                                  color: isDarkMode ? AppColors.surface.withOpacity(0.5) : Colors.black.withOpacity(0.05),
                                  border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    children: [
                                      Icon(Icons.search, color: isDarkMode ? Colors.white54 : Colors.black54),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          onChanged: (value) {
                                            setState(() => _searchQuery = value);
                                            ref.read(searchQueryProvider.notifier).state = value;
                                          },
                                          decoration: InputDecoration(
                                            hintText: "Search...",
                                            border: InputBorder.none,
                                            hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54),
                                          ),
                                          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              FadeInLeft(
                                duration: const Duration(milliseconds: 600),
                                child: Text(
                                  "Menu",
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (!isSmallScreen || constraints.maxWidth >= 600) 
                              FadeInDown(
                                duration: const Duration(milliseconds: 600),
                                child: GlassContainer(
                                  width: constraints.maxWidth < 800 ? 200 : 300,
                                  height: 50,
                                  borderRadius: 12,
                                  color: isDarkMode ? AppColors.surface.withOpacity(0.5) : Colors.black.withOpacity(0.05),
                                  border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    children: [
                                      Icon(Icons.search, color: isDarkMode ? Colors.white54 : Colors.black54),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          onChanged: (value) {
                                            setState(() => _searchQuery = value);
                                            ref.read(searchQueryProvider.notifier).state = value;
                                          },
                                          decoration: InputDecoration(
                                            hintText: "Search...",
                                            border: InputBorder.none,
                                            hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54),
                                          ),
                                          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                    ),

                    // Categories
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected = category == selectedCategory;
                          
                          return FadeInRight(
                            duration: const Duration(milliseconds: 500),
                            delay: Duration(milliseconds: index * 100),
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ref.read(selectedCategoryProvider.notifier).state = category;
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? AppColors.accent 
                                      : (isDarkMode ? AppColors.surface.withOpacity(0.3) : Colors.black.withOpacity(0.05)),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: isSelected 
                                        ? AppColors.accent 
                                        : (isDarkMode ? Colors.white24 : Colors.black12),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.accent.withOpacity(0.4),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          )
                                        ]
                                      : [],
                                ),
                                child: Center(
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      color: isSelected 
                                          ? Colors.black
                                          : (isDarkMode ? Colors.white : Colors.black87),
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSelected ? 16 : 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Menu Grid
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: childAspectRatio,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: menuItems.length,
                        itemBuilder: (context, index) {
                          final item = menuItems[index];
                          final itemKey = _getItemKey(item.id);
                          
                          return FadeInUp(
                            duration: const Duration(milliseconds: 500),
                            delay: Duration(milliseconds: index * 50),
                            child: MenuItemWidget(
                              item: item,
                              globalKey: itemKey, // Pass the key
                              onTap: () {
                                _runFlyAnimation(itemKey, item);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Cart Sidebar - Only show on large screens
              if (!isSmallScreen)
                Expanded(
                  flex: 1,
                  child: Container(
                    key: _cartKey, // Key for target
                    child: const CartSidebar(),
                  ),
                ),
            ],
          ),
        );
      }
    );
  }
}

class _FlyAnimationWidget extends StatefulWidget {
  final Offset startPosition;
  final Offset endPosition;
  final MenuItemModel item;
  final VoidCallback onComplete;

  const _FlyAnimationWidget({
    required this.startPosition,
    required this.endPosition,
    required this.item,
    required this.onComplete,
  });

  @override
  State<_FlyAnimationWidget> createState() => _FlyAnimationWidgetState();
}

class _FlyAnimationWidgetState extends State<_FlyAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _positionAnimation = Tween<Offset>(
      begin: widget.startPosition,
      end: widget.endPosition,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.8, 1.0),
    ));

    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              left: _positionAnimation.value.dx,
              top: _positionAnimation.value.dy,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.accent, width: 2),
                      image: DecorationImage(
                        image: NetworkImage(widget.item.image),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
