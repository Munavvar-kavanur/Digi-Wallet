import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../common/providers/bottom_nav_provider.dart';
import '../domain/transaction_model.dart';
import '../data/transaction_provider.dart';
import '../../settings/data/category_provider.dart';

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
    final isEditing = widget.transactionToEdit != null;
    // If presented as a modal (no back button needed usually, but drag handle is nice)
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Transaction" : "New Transaction"),
        centerTitle: true,
        automaticallyImplyLeading: false, // Hide back button in modal
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount Input
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Amount",
                  prefixText: "\$ ",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Please enter an amount";
                  if (double.tryParse(value) == null) return "Invalid amount";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Type Toggle (Disable if editing? Optional, but let's allow it)
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text("Expense"),
                    icon: Icon(Icons.outbound),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text("Income"),
                    icon: Icon(Icons.add_circle_outline),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (Set<TransactionType> newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                    // Only reset category if type changed and previous category is invalid.
                    // But simpler to just reset to null to force selection or default.
                    if (_selectedType != widget.transactionToEdit?.type) {
                        _selectedCategory = null; 
                    } else if (widget.transactionToEdit != null) {
                        _selectedCategory = widget.transactionToEdit!.category;
                    }
                  });
                },
                style:  ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                     if (states.contains(WidgetState.selected)) {
                       return _selectedType == TransactionType.income ? Colors.green.withOpacity(0.2) : Theme.of(context).colorScheme.errorContainer;
                     }
                     return null;
                  }),
                   foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                     if (states.contains(WidgetState.selected)) {
                       return _selectedType == TransactionType.income ? Colors.green : Theme.of(context).colorScheme.error;
                     }
                     return null;
                  }),
                ),
              ),
              const SizedBox(height: 16),
              
              // Category Dropdown
              Consumer(
                builder: (context, ref, child) {
                  final categories = ref.watch(categoryListProvider(_selectedType));
                  
                  // Validation logic to ensure _selectedCategory is valid in the list
                  if (_selectedCategory == null && categories.isNotEmpty) {
                       // Only auto-select first if NOT editing (or if editing but category invalid)
                       if (!isEditing) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) setState(() => _selectedCategory = categories.first);
                          });
                       }
                  } else if (_selectedCategory != null && !categories.contains(_selectedCategory)) {
                       // If selected category is not in list (e.g. was deleted or type switched), clear it
                       WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && categories.isNotEmpty) {
                             setState(() => _selectedCategory = categories.first);
                          } else if (mounted) {
                             setState(() => _selectedCategory = null);
                          }
                       });
                  }

                  return DropdownButtonFormField<String>(
                    value: (categories.contains(_selectedCategory)) ? _selectedCategory : null,
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                    decoration: const InputDecoration(
                      labelText: "Category",
                    ),
                    validator: (val) => val == null ? "Required" : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Date Picker
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Date",
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat.yMMMd().format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 16),

              // Note Input
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: "Note (Optional)",
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saveTransaction,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: Text(isEditing ? "Update Transaction" : "Save Transaction"),
                ),
              ),
              
              if (isEditing) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _deleteTransaction,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text("Delete Transaction", style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
