import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../transactions/presentation/add_transaction_screen.dart';
import '../../history/presentation/history_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../../common/providers/bottom_nav_provider.dart';
import '../../../common/widgets/expandable_navbar.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    // Map Provider State (0..3) to Navbar Index (0..3) - Direct mapping for 4 items
    final navIndex = currentIndex;

    return Scaffold(
      extendBody: true, 
      body: IndexedStack(
        index: currentIndex,
        children: const [
          DashboardScreen(),
          HistoryScreen(),
          ReportsScreen(),
          SettingsScreen(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80, right: 16), // Adjusted for "just above" feeling
        child: Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.tertiary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (context) => const AddTransactionScreen(),
                );
              },
              customBorder: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
        child: ExpandableNavbar(
          selectedIndex: navIndex, // Highlighting
          onItemSelected: (index) {
             ref.read(bottomNavIndexProvider.notifier).state = index;
          },
          items: const [
            ExpandableNavbarItem(icon: Icons.home_filled, selectedIcon: Icons.home_filled, label: "Home"),
            ExpandableNavbarItem(icon: Icons.receipt_long, selectedIcon: Icons.receipt_long, label: "History"),
            // Removed Center "Add" - moved to FAB
            ExpandableNavbarItem(icon: Icons.analytics_outlined, selectedIcon: Icons.analytics_rounded, label: "Budget"),
            ExpandableNavbarItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: "Profile"),
          ],
        ),
      ),
    );
  }
}
