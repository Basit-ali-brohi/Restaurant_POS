import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../domain/models/table_model.dart';

class TableWidget extends ConsumerStatefulWidget {
  final TableModel table;
  final VoidCallback onTap;

  const TableWidget({
    super.key,
    required this.table,
    required this.onTap,
  });

  @override
  ConsumerState<TableWidget> createState() => _TableWidgetState();
}

class _TableWidgetState extends ConsumerState<TableWidget> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    if (widget.table.status == TableStatus.occupied) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(TableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.table.status == TableStatus.occupied && !_pulseController.isAnimating) {
      _pulseController.repeat();
    } else if (widget.table.status != TableStatus.occupied && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (widget.table.status) {
      case TableStatus.available:
        statusColor = AppColors.success; // Green
        statusText = "Available";
        statusIcon = Icons.check_circle_outline;
        break;
      case TableStatus.occupied:
        statusColor = AppColors.error; // Red
        statusText = _getDurationString(widget.table.occupiedSince);
        statusIcon = Icons.timer;
        break;
      case TableStatus.reserved:
        statusColor = AppColors.info; // Blue
        statusText = "Reserved";
        statusIcon = Icons.event_seat;
        break;
      case TableStatus.cleaning:
        statusColor = AppColors.textMuted; // Grey
        statusText = "Cleaning";
        statusIcon = Icons.cleaning_services;
        break;
      case TableStatus.billing:
        statusColor = AppColors.warning; // Yellow
        statusText = "Billing";
        statusIcon = Icons.receipt_long;
        break;
      case TableStatus.outOfService:
        statusColor = const Color(0xFF64748B); // Slate
        statusText = "Out of Service";
        statusIcon = Icons.block;
        break;
    }

    Widget content = GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 1.2 : 1.0, // Increased scale
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut, // Spring animation
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Pulse Animation (Outer Glow)
                if (widget.table.status == TableStatus.occupied)
                  Opacity(
                    opacity: (1.0 - _pulseController.value),
                    child: Container(
                      width: 120 + (_pulseController.value * 30),
                      height: 120 + (_pulseController.value * 30),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accent.withOpacity(0.8), // Amber Gold border
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.5), // Amber Gold glow
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Selected Neon Ring (When pressed)
                if (_isPressed)
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accent, // Neon Amber Gold
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.8),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                
                // Main Table Widget
                child!,
              ],
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: _isPressed
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.6),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ]
                  : [
                      // Soft Glow Shadow (Matches stars/background)
                      BoxShadow(
                        color: isDarkMode ? Colors.blueAccent.withOpacity(0.15) : Colors.black.withOpacity(0.05), // Star-like glow
                        blurRadius: 30,
                        spreadRadius: 5,
                        offset: const Offset(0, 0),
                      ),
                      // Subtle drop shadow for depth
                      BoxShadow(
                        color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: GlassContainer(
              width: 120,
              height: 120,
              shape: BoxShape.circle,
              blur: 30, // Increased blur for better glassmorphism
              color: statusColor.withOpacity(isDarkMode ? 0.15 : 0.1), // Slightly more opaque
              border: Border.all(
                color: _isPressed 
                    ? AppColors.accent 
                    : (isDarkMode ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.1)), // Brighter border for neon effect
                width: _isPressed ? 3 : 2,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.table_restaurant,
                    color: isDarkMode ? Colors.white : Colors.black87, // Pure white for crispness
                    size: 22, // Smaller icon
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.table.name,
                    style: TextStyle(
                      fontSize: 18, // Larger font
                      fontWeight: FontWeight.w900, // Extra bold
                      color: isDarkMode ? Colors.white : Colors.black87,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(isDarkMode ? 0.5 : 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2), // Pill background
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withOpacity(0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 10, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText.toUpperCase(),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 9, // Smaller text
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.table.status == TableStatus.occupied)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "Guests: ${widget.table.seats}",
                        style: TextStyle(
                          color: isDarkMode ? Colors.white54 : Colors.black54,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return content;
  }

  String _getDurationString(DateTime? since) {
    if (since == null) return "Occupied";
    final duration = DateTime.now().difference(since);
    return "${duration.inMinutes}m";
  }
}
