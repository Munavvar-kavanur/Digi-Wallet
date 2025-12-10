import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/transaction_model.dart';
import 'transaction_repository.dart';

class TransactionNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() async {
    return _fetchTransactions();
  }

  Future<List<Transaction>> _fetchTransactions() async {
    final repository = ref.read(transactionRepositoryProvider);
    final transactions = await repository.getTransactions();
    // Return reversed list to show newest first
    return transactions.reversed.toList();
  }

  Future<void> addTransaction(Transaction transaction) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.addTransaction(transaction);
      return _fetchTransactions();
    });
  }

  Future<void> deleteTransaction(dynamic key) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.deleteTransaction(key);
      return _fetchTransactions();
    });
  }

  Future<void> editTransaction(dynamic key, Transaction transaction) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.editTransaction(key, transaction);
      return _fetchTransactions();
    });
  }
}

final transactionListProvider = AsyncNotifierProvider<TransactionNotifier, List<Transaction>>(() {
  return TransactionNotifier();
});

final totalBalanceProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionListProvider).asData?.value ?? [];
  return transactions.fold(0, (sum, item) {
    if (item.type == TransactionType.income) {
      return sum + item.amount;
    } else {
      return sum - item.amount;
    }
  });
});

final totalIncomeProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionListProvider).asData?.value ?? [];
  return transactions.where((t) => t.type == TransactionType.income).fold(0, (sum, t) => sum + t.amount);
});

final totalExpenseProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionListProvider).asData?.value ?? [];
  return transactions.where((t) => t.type == TransactionType.expense).fold(0, (sum, t) => sum + t.amount);
});
