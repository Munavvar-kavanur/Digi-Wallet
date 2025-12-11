import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../common/providers/bottom_nav_provider.dart';
import '../domain/transaction_model.dart';
import '../data/transaction_provider.dart';
import '../data/transaction_provider.dart';
import '../../settings/data/category_provider.dart';
import '../../../common/providers/currency_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? transactionToEdit;
  final dynamic transactionKey;

  const AddTransactionScreen({super.key, this.transactionToEdit, this.transactionKey});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late TransactionType _selectedType;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    final t = widget.transactionToEdit;
    _amountController = TextEditingController(text: t != null ? t.amount.toString() : '');
    _noteController = TextEditingController(text: t?.note ?? '');
    _selectedDate = t?.date ?? DateTime.now();
    _selectedType = t?.type ?? TransactionType.expense;
    _selectedCategory = t?.category; // Will be validated by dropdown
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a category")));
         return;
      }

      final transaction = Transaction(
        amount: double.parse(_amountController.text),
        category: _selectedCategory!,
        date: _selectedDate,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        type: _selectedType,
      );

      final notifier = ref.read(transactionListProvider.notifier);
      if (widget.transactionToEdit != null) {
        await notifier.editTransaction(widget.transactionKey, transaction);
      } else {
        await notifier.addTransaction(transaction);
        // Clear inputs after adding new
        _amountController.clear();
        _noteController.clear();
        setState(() {
           _selectedCategory = null; 
        });
      }

      if (mounted) {
        if (Navigator.canPop(context)) {
           Navigator.pop(context);
        } else {
           // Switch to Home tab
           ref.read(bottomNavIndexProvider.notifier).state = 0;
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transaction Saved")));
        }
      }
    }
  }

  void _deleteTransaction() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Transaction"),
        content: const Text("Are you sure you want to delete this transaction?"),
        actions: [
           TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
           TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete")),
        ],
      )
    );

    if (confirm == true) {
      await ref.read(transactionListProvider.notifier).deleteTransaction(widget.transactionKey);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = ref.watch(currencySymbolProvider);
    final isEditing = widget.transactionToEdit != null;
    final primaryColor = _selectedType == TransactionType.income 
        ? const Color(0xFF10B981) // Emerald 500
        : const Color(0xFFEF4444); // Red 500

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  Text(
                    isEditing ? "Edit Transaction" : "New Transaction",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 48), // Placeholder for balance
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Type Toggle (Pill)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildTypeButton(TransactionType.expense, "Expense", Icons.arrow_outward),
                              const SizedBox(width: 4),
                              _buildTypeButton(TransactionType.income, "Income", Icons.arrow_downward),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Large Amount Input
                        Text(
                          "Enter Amount",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        IntrinsicWidth(
                          child: TextFormField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 48, 
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                            decoration: InputDecoration(
                              prefixText: "$currencySymbol ",
                              prefixStyle: TextStyle(
                                fontSize: 48, 
                                fontWeight: FontWeight.bold, 
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                              ),
                              border: InputBorder.none,
                              hintText: "0",
                              hintStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return null; // Handled by button usage
                              if (double.tryParse(value) == null) return "Invalid";
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Section Title
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Category",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Horizontal Category Chips
                        Consumer(
                          builder: (context, ref, _) {
                            final categories = ref.watch(categoryListProvider(_selectedType));
                             // Auto-select valid logic remains similar but integrated in build
                            if (_selectedCategory == null && categories.isNotEmpty && !isEditing) {
                                Future.microtask(() {
                                  if (mounted) setState(() => _selectedCategory = categories.first);
                                });
                            }

                            return SizedBox(
                              height: 50,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: categories.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final cat = categories[index];
                                  final isSelected = _selectedCategory == cat;
                                  return ChoiceChip(
                                    label: Text(cat),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      if (selected) setState(() => _selectedCategory = cat);
                                    },
                                    selectedColor: primaryColor.withOpacity(0.2),
                                    backgroundColor: Theme.of(context).colorScheme.surface,
                                    labelStyle: TextStyle(
                                      color: isSelected ? primaryColor : Theme.of(context).colorScheme.onSurface,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: isSelected ? primaryColor : Theme.of(context).colorScheme.outline.withOpacity(0.5),
                                      ),
                                    ),
                                    showCheckmark: false,
                                  );
                                },
                              ),
                            );
                          }
                        ),
                        const SizedBox(height: 32),

                        // Date & Note Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Date", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: _pickDate,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.calendar_today, size: 18, color: Theme.of(context).colorScheme.primary),
                                          const SizedBox(width: 8),
                                          Text(DateFormat.yMMMd().format(_selectedDate)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                              Text("Note", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _noteController,
                                decoration: InputDecoration(
                                  hintText: "Add a note...",
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                              ),
                           ],
                        ),

                        // Bottom Actions
                        const SizedBox(height: 48),
                        
                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: _saveTransaction,
                            style: FilledButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              shadowColor: primaryColor.withOpacity(0.4),
                            ),
                            child: Text(
                              isEditing ? "Update Transaction" : "Save Transaction",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        
                        if (isEditing)
                           Padding(
                             padding: const EdgeInsets.only(top: 16),
                             child: TextButton(
                               onPressed: _deleteTransaction,
                               child: Text("Delete Transaction", style: TextStyle(color: Theme.of(context).colorScheme.error)),
                             ),
                           )

                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(TransactionType type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    final color = type == TransactionType.income 
        ? const Color(0xFF10B981) 
        : const Color(0xFFEF4444);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
           // Logic to clear category if not valid for new type
           if (_selectedType != widget.transactionToEdit?.type) {
                _selectedCategory = null; 
           } else if (widget.transactionToEdit != null) {
                _selectedCategory = widget.transactionToEdit!.category;
           }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).scaffoldBackgroundColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
