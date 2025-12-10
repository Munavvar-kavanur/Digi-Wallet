import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/transaction_repository.dart';
import '../data/transaction_provider.dart';
import '../../settings/data/category_repository.dart';

enum SyncStatus { synced, syncing, error, offline }

class SyncService extends StateNotifier<SyncStatus> {
  final TransactionRepository _repository;
  final Ref _ref;
  Timer? _timer;

  SyncService(this._repository, this._ref) : super(SyncStatus.synced) {
    _init();
  }

  void _init() {
    syncNow();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      syncNow();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> syncNow() async {
    state = SyncStatus.syncing;
    try {
      // 1. Fetch ALL data (Transactions + Categories)
      final data = await _repository.fetchFullData();
      
      if (data != null) {
        // 2. Sync Transactions
        if (data.containsKey('data') && data['data'] is List) {
           await _repository.syncLocalData(data['data']);
        }

        // 3. Sync Categories
        if (data.containsKey('categories') && data['categories'] is Map) {
           final catData = data['categories'] as Map;
           final expenses = catData['expense'] is List ? catData['expense'] : [];
           final incomes = catData['income'] is List ? catData['income'] : [];
           
           final catRepo = _ref.read(categoryRepositoryProvider);
           await catRepo.syncWithRemoteData(expenses, incomes);
        }
        
        // 4. Force UI Refresh
        _ref.invalidate(transactionListProvider);
        // We might want to invalidate category providers too, but they usually watch Hive directly or via Notifier.
        // Let's invalidate them to be safe if they cache state.
        // Actually, CategoryProvider is a StateNotifier that inits from Hive. 
        // We probably need to tell it to reload? Or just trust next rebuild?
        // Since `_loadAndSeed` is called in constructor, simply invalidating might re-create it.
        // But `categoryListProvider` is a family.
        // Since we are updating Hive in background, user might not see changes until they re-enter screen.
        // For now, this is acceptable for background sync.
      } else {
        // Null means no URL or error caught inside (but we catch outside). 
        // Or essentially "Local Mode".
      }

      state = SyncStatus.synced;
    } catch (e) {
      debugPrint("Sync Service Error: $e");
      state = SyncStatus.error;
    }
  }
}

final syncServiceProvider = StateNotifierProvider<SyncService, SyncStatus>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return SyncService(repository, ref);
});
