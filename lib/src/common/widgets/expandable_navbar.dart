import 'package:flutter/material.dart';

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark background as per image
        borderRadius: BorderRadius.circular(40), // Full Pill Shape
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Shrink to fit content? Or full width?
        // Detailed design: "Short and Expand". 
        // If we want it to float and be short, mainAxisSize.min is good.
        // But for a persistent navbar, usually full width or close to it.
        // Let's use flexible layout.
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (int i = 0; i < items.length; i++) 
             _buildItem(context, i),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = items[index];
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onItemSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: isSelected 
            ? const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
            : const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? item.selectedIcon : item.icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                item.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
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
