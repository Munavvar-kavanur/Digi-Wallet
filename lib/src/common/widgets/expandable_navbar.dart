import 'package:flutter/material.dart';
import 'dart:ui';

class ExpandableNavbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<ExpandableNavbarItem> items;
  final Widget? centerButton; // For FAB integration if needed (or we overlap)

  const ExpandableNavbar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    this.centerButton,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Frozen Glass Blur
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark 
                  ? [
                      Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.6),
                      Theme.of(context).colorScheme.surface.withOpacity(0.6),
                    ]
                  : [
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Theme.of(context).colorScheme.tertiary.withOpacity(0.05),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            color: isDark ? null : Colors.white.withOpacity(0.7), // Glassy white base
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              // Main Shadow / Glow
              BoxShadow(
                color: isDark 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.5) // Glow in dark mode
                    : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                blurRadius: isDark ? 25 : 20,
                offset: const Offset(0, 10),
                spreadRadius: isDark ? 1 : 2,
              ),
              // Secondary reflection for glass feeling
              if (!isDark)
              BoxShadow(
                color: Colors.white.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(-5, -5),
              ),
            ],
            border: Border.all(
              color: isDark 
                  ? Colors.white.withOpacity(0.1) 
                  : Theme.of(context).colorScheme.primary.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < items.length; i++) 
                 _buildItem(context, i),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = items[index];
    final isSelected = selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Modern Palette
    final activeColor = Theme.of(context).colorScheme.primary;
    final activeBg = isDark 
        ? activeColor.withOpacity(0.2) 
        : activeColor.withOpacity(0.1);

    return GestureDetector(
      onTap: () => onItemSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: isSelected 
            ? const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
            : const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? item.selectedIcon : item.icon,
              color: isSelected 
                  ? activeColor 
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                item.label,
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ExpandableNavbarItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const ExpandableNavbarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
