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
        padding: const EdgeInsets.only(bottom: 4, right: 16), // "Just near" the navbar (approx 4px)
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // Glass Effect
            child: Container(
              height: 64, // Slightly larger for better touch target and presence
              width: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.8), // Glassy Primary
                    Theme.of(context).colorScheme.tertiary.withOpacity(0.6), // Glassy Tertiary
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.35), // Frosted Edge
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                    spreadRadius: 4,
                  ),
                  // Inner light reflection for 3D effect
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(-2, -2),
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
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
                ),
              ),
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
