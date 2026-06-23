import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../domain/models/order_model.dart';
import '../providers/kitchen_provider.dart';

class OrderCard extends ConsumerStatefulWidget {
  final OrderModel order;

  const OrderCard({super.key, required this.order});

  @override
  ConsumerState<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<OrderCard> with TickerProviderStateMixin {
  late Timer _timer;
  Duration _duration = Duration.zero;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  late AnimationController _dismissController;
  late Animation<double> _sizeFactor;
  late Animation<Offset> _slideOffset;

  @override
  void initState() {
    super.initState();
    _updateDuration();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateDuration());

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(_blinkController);
    _dismissController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _sizeFactor = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _dismissController, curve: Curves.easeInOut),
    );
    _slideOffset = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.2)).animate(
      CurvedAnimation(parent: _dismissController, curve: Curves.easeInOut),
    );
  }

  void _updateDuration() {
    if (mounted) {
      setState(() {
        _duration = DateTime.now().difference(widget.order.timestamp);
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _blinkController.dispose();
    _dismissController.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    if (widget.order.status == OrderStatus.ready) return AppColors.success;
    
    // Timer based color
    if (_duration.inMinutes >= 15) return AppColors.error;
    if (_duration.inMinutes >= 10) return AppColors.warning;
    return AppColors.success;
  }

  bool _shouldBlink() =>
      widget.order.status != OrderStatus.ready && _duration.inMinutes >= 15;

  bool get _isCritical =>
      widget.order.status != OrderStatus.ready && _duration.inMinutes >= 20;

  bool get _isCooking => widget.order.status == OrderStatus.cooking;

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "${d.inHours > 0 ? '${d.inHours}:' : ''}$minutes:$seconds";
  }

  void _advanceStatus() {
    final notifier = ref.read(kitchenProvider.notifier);
    if (widget.order.status == OrderStatus.pending) {
      notifier.updateStatus(widget.order.id, OrderStatus.cooking);
    } else if (widget.order.status == OrderStatus.cooking) {
      notifier.updateStatus(widget.order.id, OrderStatus.ready);
    } else if (widget.order.status == OrderStatus.ready) {
      notifier.completeOrder(widget.order.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final isLate = DateTime.now().difference(widget.order.timestamp).inMinutes > 15;
    final statusColor = _getStatusColor();
    final isNewPulse = DateTime.now().difference(widget.order.timestamp).inSeconds < 6;
    
    // Priority Border Logic
    final borderColor = isNewPulse
        ? AppColors.accent.withOpacity(0.8 * _blinkAnimation.value)
        : isLate
            ? AppColors.error
            : _isCooking
                ? Colors.orange.withOpacity(_blinkAnimation.value)
                : (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1));

    return AnimatedBuilder(
      animation: _blinkAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: _isCritical ? const Color(0xFF3B0000) : (isDarkMode ? AppColors.surface : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: isNewPulse ? 3 : (isLate || _isCooking ? 2 : 1),
            ),
            boxShadow: isNewPulse
                ? [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.5 * _blinkAnimation.value),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ]
                : isLate
                    ? [
                        BoxShadow(
                          color: AppColors.error.withOpacity(0.4 * _blinkAnimation.value),
                          blurRadius: 20,
                          spreadRadius: 2,
                        )
                      ]
                    : _isCooking
                        ? [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3 * _blinkAnimation.value),
                              blurRadius: 15,
                              spreadRadius: 1,
                            )
                          ]
                        : [
                            if (!isDarkMode)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                          ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.order.items.isEmpty)
                Center(child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("Empty Order", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black54)),
                )),
              if (widget.order.items.isNotEmpty) ...[
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.order.orderType == OrderType.dineIn 
                          ? "Table ${widget.order.tableName}" 
                          : "Takeaway #${widget.order.tableName.replaceAll('Takeaway #', '')}",
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.order.orderType == OrderType.takeaway ? Colors.blue.withOpacity(0.2) : Colors.purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.order.orderType == OrderType.takeaway ? Colors.blue : Colors.purple,
                        ),
                      ),
                      child: Text(
                        widget.order.orderType == OrderType.takeaway ? "Takeaway" : "Dine-In",
                        style: TextStyle(
                          color: widget.order.orderType == OrderType.takeaway ? Colors.blue : Colors.purpleAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLate ? AppColors.error : AppColors.error.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(_duration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Status Badge
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                      widget.order.status.name.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                Divider(color: isDarkMode ? Colors.white24 : Colors.black12, height: 24),
            
                // Items List
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: widget.order.items.length,
                    separatorBuilder: (context, index) => Divider(color: isDarkMode ? Colors.white10 : Colors.black12),
                    itemBuilder: (context, index) {
                      final item = widget.order.items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12),
                              ),
                              child: Text(
                                "${item.quantity}x",
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.menuItem.name,
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (item.modifiers.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: item.modifiers.map((mod) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: isDarkMode ? Colors.white12 : Colors.black12),
                                          ),
                                          child: Text(
                                            mod,
                                            style: TextStyle(
                                              color: isDarkMode ? Colors.white70 : Colors.black54,
                                              fontSize: 12,
                                            ),
                                          ),
                                        )).toList(),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              // Action Button
              SizedBox(
                width: double.infinity,
                child: Opacity(
                  opacity: _isCritical ? _blinkAnimation.value : 1.0,
                  child: ElevatedButton(
                    onPressed: _advanceStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
                      foregroundColor: Colors.white, // AppColors.primary, // Changed to white for better contrast
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: statusColor.withOpacity(0.5),
                    ),
                    child: Text(
                      widget.order.status == 'pending' 
                        ? 'START COOKING' 
                        : widget.order.status == 'cooking'
                            ? 'MARK READY'
                            : 'COMPLETE',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.0,
                        color: Colors.white, // Ensure text is white
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
