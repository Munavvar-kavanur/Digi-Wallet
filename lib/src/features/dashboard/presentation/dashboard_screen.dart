import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../transactions/presentation/add_transaction_screen.dart';
import '../../transactions/data/transaction_provider.dart';
import '../../transactions/data/sync_service.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../../common/providers/bottom_nav_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get time of day for greeting
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning,' : hour < 17 ? 'Good Afternoon,' : 'Good Evening,';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. Custom Header (Replaces standard AppBar for a cleaner look)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "My Wallet",
                        style: TextStyle(
                          fontSize: 24,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Profile or Settings quick access could go here
                  Row(
                    children: [
                      _SyncIndicator(),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                        ),
                        child: const Icon(Icons.notifications_none_rounded, size: 24),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 2. Premium Balance Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF6366F1) // Indigo Primary
                          : const Color(0xFF4F46E5),
                      Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF2DD4BF) // Teal Secondary
                          : const Color(0xFF0EA5E9), // Sky Blue
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total Balance", 
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          )
                        ),
                        Icon(Icons.more_horiz, color: Colors.white.withOpacity(0.6)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Consumer(
                      builder: (context, ref, child) {
                        final balance = ref.watch(totalBalanceProvider);
                        return Text(
                          "\$${balance.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1.5,
                            height: 1.1,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    // Income / Expense Stats
                    Row(
                      children: [
                        Expanded(
                          child: Consumer(
                            builder: (context, ref, child) {
                              final income = ref.watch(totalIncomeProvider);
                              return _buildStatItem(context, "Income", income, Icons.arrow_downward_rounded, Colors.white);
                            }
                          ),
                        ),
                        Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
                        Expanded(
                          child: Consumer(
                            builder: (context, ref, child) {
                              final expense = ref.watch(totalExpenseProvider); // Requires provider logic
                              return _buildStatItem(context, "Expense", expense, Icons.arrow_upward_rounded, Colors.white.withOpacity(0.9));
                            }
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),

          // 3. Transactions Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Recent Activity", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: (){
                       ref.read(bottomNavIndexProvider.notifier).state = 1; // 1 is History
                    }, 
                    child: Text("See all", style: TextStyle(color: Theme.of(context).colorScheme.primary))
                  ),
                ],
              ),
            ),
          ),
          
          // List
          Consumer(
            builder: (context, ref, child) {
              final transactionsAsync = ref.watch(transactionListProvider);
              return transactionsAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long_rounded, size: 64, color: Theme.of(context).disabledColor.withOpacity(0.3)),
                              const SizedBox(height: 16),
                              Text("No transactions yet", style: TextStyle(color: Theme.of(context).disabledColor)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  // Show only first 5 on dashboard
                  final displayList = transactions.take(5).toList();
                  
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final transaction = displayList[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: _TransactionTile(transaction: transaction),
                        );
                      },
                      childCount: displayList.length,
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                error: (err, stack) => SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(24), child: Text("Error: $err"))),
              );
            },
          ),
          
          // Bottom Padding for FAB/Navbar
          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, double amount, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
            Text(
              "\$${amount.toStringAsFixed(0)}", 
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w600)
            ),
          ],
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    return InkWell(
      onTap: () {
         Navigator.push(context, MaterialPageRoute(builder: (_) => AddTransactionScreen(
            transactionToEdit: transaction,
            transactionKey: transaction.key,
          )));
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF1E293B) // Slate 800
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.05),
          ),
          boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isIncome 
                    ? const Color(0xFF10B981).withOpacity(0.1) // Emerald
                    : const Color(0xFFEF4444).withOpacity(0.1), // Red
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForCategory(transaction.category),
                color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.category, 
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16
                    )
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat.MMMd().format(transaction.date), // Short date
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                      fontSize: 12
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "${isIncome ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isIncome ? const Color(0xFF10B981) : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
      // Duplicate helper for local scope or move to utils
    switch (category) {
      case 'Food': return Icons.fastfood_rounded;
      case 'Transport': return Icons.directions_bus_rounded;
      case 'Shopping': return Icons.shopping_bag_rounded;
      case 'Entertainment': return Icons.confirmation_number_rounded;
      case 'Bills': return Icons.receipt_long_rounded;
      case 'Salary': return Icons.attach_money_rounded;
      case 'Freelance': return Icons.laptop_mac_rounded;
      case 'Gift': return Icons.card_giftcard_rounded;
      case 'Investments': return Icons.trending_up_rounded;
      default: return Icons.category_rounded;
    }
  }
}

class _SyncIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch provider to keep it alive and get state
    final status = ref.watch(syncServiceProvider);
    
    Color color;
    IconData icon;
    String tooltip;

    switch (status) {
      case SyncStatus.synced:
        color = Colors.green;
        icon = Icons.cloud_done_rounded;
        tooltip = "Synced";
        break;
      case SyncStatus.syncing:
        color = Colors.blue;
        icon = Icons.sync_rounded;
        tooltip = "Syncing...";
        break;
      case SyncStatus.error:
        color = Colors.red;
        icon = Icons.cloud_off_rounded;
        tooltip = "Sync Error";
        break;
      case SyncStatus.offline:
      default:
        color = Colors.grey;
        icon = Icons.cloud_queue_rounded;
        tooltip = "Offline";
    }

    // Animation for syncing
    if (status == SyncStatus.syncing) {
       return Container(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: 20, 
            height: 20, 
            child: CircularProgressIndicator(strokeWidth: 2, color: color)
          ),
       );
    }

    return Tooltip(
      message: tooltip,
      child: Container(
         padding: const EdgeInsets.all(8),
         decoration: BoxDecoration(
           color: color.withOpacity(0.1),
           shape: BoxShape.circle,
         ),
         child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
