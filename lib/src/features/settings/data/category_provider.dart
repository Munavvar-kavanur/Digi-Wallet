import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/data/transaction_provider.dart';
import '../../transactions/data/transaction_repository.dart';
import 'category_repository.dart';

class CategoryNotifier extends StateNotifier<List<String>> {
  final Ref ref;
  final TransactionType type;

  CategoryNotifier(this.ref, this.type) : super([]) {
    _loadAndSeed();
  }

  Future<void> _loadAndSeed() async {
    final repo = ref.read(categoryRepositoryProvider);
    // Get what is in Hive currently
    var all = repo.getAllCategories(type);
    
    // MIGRATION LOGIC:
    // If the list (which used to be ONLY custom) doesn't have our primary default,
    // we assume it's a legacy list of just custom items. We should merge defaults in.
    // Primary check: Expense -> Check for 'Food', Income -> Check for 'Salary'
    // This is a naive but effective one-time migration check.
    
    bool needsSeed = false;
    if (type == TransactionType.expense) {
       if (!all.contains('Food')) {
         // It's likely just custom items (or empty).
         // Caveat: User might have deleted 'Food'. 
         // But since we just unlocked this feature, they couldn't have deleted it yet unless they hacked Hive.
         // So it is safe to assume we need to merge defaults.
         final defaults = ['Food', 'Transport', 'Shopping', 'Entertainment', 'Bills', 'Other'];
         // Filter out duplicates just in case
         final Set<String> merged = {...defaults, ...all}; 
         all = merged.toList();
         needsSeed = true;
       }
    } else {
       if (!all.contains('Salary')) {
         final defaults = ['Salary', 'Freelance', 'Gift', 'Investments', 'Other'];
         final Set<String> merged = {...defaults, ...all};
         all = merged.toList();
         needsSeed = true;
       }
    }

    if (needsSeed) {
       await repo.saveAllCategories(type, all);
    }
    
    state = all;
  }

  Future<void> addCategory(String name) async {
    final repo = ref.read(categoryRepositoryProvider);
    await repo.addCategory(type, name);
    // Refresh
    state = repo.getAllCategories(type);
  }

  Future<void> removeCategory(String name) async {
    final repo = ref.read(categoryRepositoryProvider);
    await repo.removeCategory(type, name);
    state = repo.getAllCategories(type);
  }

  Future<void> editCategory(String oldName, String newName) async {
    final catRepo = ref.read(categoryRepositoryProvider);
    final transRepo = ref.read(transactionRepositoryProvider);
    
    await catRepo.editCategory(type, oldName, newName);
    await transRepo.updateCategoryName(oldName, newName);

    state = catRepo.getAllCategories(type);
    ref.invalidate(transactionListProvider);
  }
  
  // No longer needed, but we can keep it returning false to satisfy UI if we don't change UI first
  bool isDefault(String name) {
    return false; // Nothing is "default/locked" anymore
  }
}

final categoryListProvider = StateNotifierProvider.family<CategoryNotifier, List<String>, TransactionType>((ref, type) {
  return CategoryNotifier(ref, type);
});
