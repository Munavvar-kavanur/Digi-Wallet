import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../transactions/data/transaction_provider.dart';
import '../../transactions/domain/transaction_model.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _touchedIndex = -1;
  int _barTouchedIndex = -1;
  String _filter = 'Month'; // Month, Week

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionListProvider).value ?? [];
    
    // --- Data Processing ---
    final now = DateTime.now();
    final filteredTransactions = transactions.where((t) {
      if (t.type == TransactionType.income) return false;
      if (_filter == 'Week') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        return t.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && t.date.isBefore(endOfWeek);
      } else {
        return t.date.month == now.month && t.date.year == now.year;
      }
    }).toList();

    final totalExpense = filteredTransactions.fold(0.0, (sum, t) => sum + t.amount);
    
    // Category Data
    final categoryTotals = <String, double>{};
    for (var t in filteredTransactions) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
    }
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Daily Data (for Bar Chart)
    // Map of Day -> Amount
    final dailyTotals = <int, double>{};
    // Initialize days
    int daysInPeriod = _filter == 'Week' ? 7 : DateTime(now.year, now.month + 1, 0).day;
    for (int i = 1; i <= daysInPeriod; i++) {
        dailyTotals[i] = 0.0;
    }
    
    for (var t in filteredTransactions) {
      int day = _filter == 'Week' ? t.date.weekday : t.date.day; // Week: 1=Mon, Month: 1=1st
      dailyTotals[day] = (dailyTotals[day] ?? 0) + t.amount;
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. Header
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text(
                        "Analytics",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                   // Custom Filter Toggle
                   Container(
                     height: 40,
                     padding: const EdgeInsets.all(4),
                     decoration: BoxDecoration(
                       color: Theme.of(context).colorScheme.surfaceContainerHighest,
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: Row(
                       children: [
                         _buildFilterTab("Week", _filter == "Week"),
                         _buildFilterTab("Month", _filter == "Month"),
                       ],
                     ),
                   )
                ],
              ),
            ),
          ),

          if (filteredTransactions.isEmpty) 
             SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart_rounded, size: 80, color: Theme.of(context).disabledColor.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text("No data for this ${_filter.toLowerCase()}", style: TextStyle(color: Theme.of(context).disabledColor)),
                    ],
                  ),
                ),
             )
          else ...[
             // 2. Total Card
             SliverToBoxAdapter(child: Padding(
               padding: const EdgeInsets.symmetric(horizontal: 24),
               child: _buildTotalCard(context, totalExpense),
             )),

             // 3. Bar Chart (Trends)
             SliverToBoxAdapter(
               child: Padding(
                 padding: const EdgeInsets.all(24.0),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text("Activity Trend", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                     const SizedBox(height: 24),
                     SizedBox(
                       height: 200,
                       child: BarChart(
                         BarChartData(
                           barTouchData: BarTouchData(
                             touchTooltipData: BarTouchTooltipData(
                               getTooltipColor: (_) => Theme.of(context).colorScheme.onSurface,
                               getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    '\$${rod.toY.round()}',
                                    TextStyle(
                                      color: Theme.of(context).colorScheme.surface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                               },
                             ),
                             touchCallback: (e, r) {
                               setState(() {
                                 if (r?.spot != null && e.isInterestedForInteractions) {
                                   _barTouchedIndex = r!.spot!.touchedBarGroupIndex;
                                 } else {
                                   _barTouchedIndex = -1;
                                 }
                               });
                             }
                           ),
                           titlesData: FlTitlesData(
                             show: true,
                             rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                             topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                             bottomTitles: AxisTitles(
                               sideTitles: SideTitles(
                                 showTitles: true,
                                 getTitlesWidget: (val, meta) {
                                    int v = val.toInt();
                                    if (v % (_filter == 'Week' ? 1 : 5) != 0) return const SizedBox.shrink();
                                    String text = '';
                                    if (_filter == 'Week') {
                                       const days = ['M','T','W','T','F','S','S'];
                                       if (v > 0 && v <= 7) text = days[v-1];
                                    } else {
                                       text = v.toString();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(text, style: TextStyle(fontSize: 10, color: Theme.of(context).disabledColor)),
                                    );
                                 },
                               ),
                             ),
                             leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                           ),
                           borderData: FlBorderData(show: false),
                           gridData: FlGridData(show: false),
                           barGroups: _generateBarGroups(dailyTotals, context),
                         )
                       ),
                     ),
                   ],
                 ),
               ),
             ),

             // 4. Donut Chart
             SliverToBoxAdapter(
               child: Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 24.0),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text("Breakdown", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                     const SizedBox(height: 24),
                     SizedBox(
                       height: 240,
                       child: Stack(
                         alignment: Alignment.center,
                         children: [
                           PieChart(
                             PieChartData(
                               pieTouchData: PieTouchData(
                                 touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                   setState(() {
                                     if (!event.isInterestedForInteractions ||
                                         pieTouchResponse == null ||
                                         pieTouchResponse.touchedSection == null) {
                                       _touchedIndex = -1;
                                       return;
                                     }
                                     _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                   });
                                 },
                               ),
                               borderData: FlBorderData(show: false),
                               sectionsSpace: 4,
                               centerSpaceRadius: 50,
                               sections: _generatePieSections(sortedCategories, totalExpense, context),
                             ),
                           ),
                           // Center Text
                           Column(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               Text("Total", style: TextStyle(fontSize: 12, color: Theme.of(context).disabledColor)),
                               Text(
                                 "\$${totalExpense.toStringAsFixed(0)}",
                                 style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                               ),
                             ],
                           )
                         ],
                       ),
                     ),
                   ],
                 ),
               ),
             ),
             
             // 5. Category List
             SliverPadding(
               padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
               sliver: SliverList(
                 delegate: SliverChildBuilderDelegate(
                   (context, index) {
                     final entry = sortedCategories[index];
                     return _buildCategoryItem(context, entry.key, entry.value, totalExpense);
                   },
                   childCount: sortedCategories.length,
                 ),
               ),
             ),
          ]
        ],
      ),
    );
  }

  Widget _buildFilterTab(String text, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _filter = text),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).scaffoldBackgroundColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).disabledColor,
            fontSize: 13
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCard(BuildContext context, double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
             Colors.indigo.shade400,
             Colors.teal.shade300,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
             color: Colors.indigo.withOpacity(0.3),
             blurRadius: 16,
             offset: const Offset(0, 8),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Total Budget Spent", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            "\$${total.toStringAsFixed(2)}", 
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1)
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8)
            ),
            child: Text(
              _filter == 'Week' ? "Last 7 Days" : "This Month", 
              style: const TextStyle(color: Colors.white, fontSize: 12)
            ),
          )
        ],
      ),
    );
  }

  List<BarChartGroupData> _generateBarGroups(Map<int, double> dailyTotals, BuildContext context) {
      return dailyTotals.entries.map((e) {
         final isTouched = e.key == _barTouchedIndex + 1; // Bar index (0-based) vs Key (1-based)
         // Actually FlChart group indexes are 0 based.
         // Let's rely on sorted keys (1..N) and index map.
         return BarChartGroupData(
           x: e.key,
           barRods: [
             BarChartRodData(
               toY: e.value,
               color: isTouched ? Theme.of(context).primaryColor : Theme.of(context).primaryColor.withOpacity(0.5),
               width: _filter == 'Week' ? 16 : 6,
               borderRadius: BorderRadius.circular(4),
               backDrawRodData: BackgroundBarChartRodData(show: true, toY: _getMax(dailyTotals), color: Theme.of(context).dividerColor.withOpacity(0.05))
             )
           ]
         );
      }).toList();
  }
  
  double _getMax(Map<int, double> data) {
    double m = 0;
    for(var v in data.values) { if(v > m) m = v; }
    return m == 0 ? 100 : m * 1.2;
  }

  List<PieChartSectionData> _generatePieSections(List<MapEntry<String, double>> categories, double total, BuildContext context) {
    return List.generate(categories.length, (i) {
      final isTouched = i == _touchedIndex;
      final category = categories[i];
      final percentage = (category.value / total) * 100;
      final color = _getColorFromString(category.key); // Use string hash for consistency

      return PieChartSectionData(
        color: color,
        value: category.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: isTouched ? 60.0 : 50.0,
        titleStyle: TextStyle(
          fontSize: isTouched ? 16.0 : 12.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Widget _buildCategoryItem(BuildContext context, String category, double amount, double total) {
    final percentage = (amount / total);
    final color = _getColorFromString(category);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
        ]
      ),
      child: Row(
        children: [
           Container(
             padding: const EdgeInsets.all(10),
             decoration: BoxDecoration(
               color: color.withOpacity(0.1),
               shape: BoxShape.circle,
             ),
             child: Icon(_getIconForCategory(category), size: 18, color: color),
           ),
           const SizedBox(width: 16),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text(category, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                     Text("\$${amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w600)),
                   ],
                 ),
                 const SizedBox(height: 8),
                 ClipRRect(
                   borderRadius: BorderRadius.circular(4),
                   child: LinearProgressIndicator(
                     value: percentage,
                     backgroundColor: Theme.of(context).dividerColor.withOpacity(0.1),
                     valueColor: AlwaysStoppedAnimation(color),
                     minHeight: 6,
                   ),
                 ),
               ],
             ),
           )
        ],
      ),
    );
  }
  
  IconData _getIconForCategory(String category) {
    // Utilities could be shared but for now local is faster
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

  Color _getColorFromString(String category) {
    final colors = [
        Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.pink, Colors.indigo, Colors.amber 
    ];
    return colors[category.length % colors.length];
  }
}
