import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../../common/providers/theme_provider.dart';

class CategoryRepository {
  final Box _box;
  final SharedPreferences _prefs;

  CategoryRepository(this._box, this._prefs);

  static const _defaultExpenseCategories = ['Food', 'Transport', 'Shopping', 'Entertainment', 'Bills', 'Other'];
  static const _defaultIncomeCategories = ['Salary', 'Freelance', 'Gift', 'Investments', 'Other'];

  String? get _sheetUrl => _prefs.getString('google_sheet_url')?.trim().replaceAll(RegExp(r'\s+'), '');

  List<String> getAllCategories(TransactionType type) {
      final key = _getKey(type);
      final raw = _box.get(key);
      
      if (raw == null) {
          return type == TransactionType.expense ? _defaultExpenseCategories : _defaultIncomeCategories;
      }
      
      return List<String>.from(raw);
  }

  Future<void> saveAllCategories(TransactionType type, List<String> categories, {bool pushToRemote = true}) async {
      final key = _getKey(type);
      await _box.put(key, categories);

      if (!pushToRemote) return;

      // Remote Sync (Fire and Forget)
      final url = _sheetUrl;
      if (url != null && url.isNotEmpty) {
          http.post(
            Uri.parse(url),
            body: jsonEncode({
              'action': 'saveCategories',
              'type': type == TransactionType.expense ? 'expense' : 'income',
              'categories': categories,
            }),
          ).catchError((e) => debugPrint("Category Sync Failed: $e"));
      }
  }

  Future<void> addCategory(TransactionType type, String name) async {
    final current = getAllCategories(type);
    if (!current.contains(name)) {
      final newList = List<String>.from(current)..add(name);
      await saveAllCategories(type, newList);
    }
  }

  Future<void> removeCategory(TransactionType type, String name) async {
    final current = getAllCategories(type);
    final newList = List<String>.from(current)..remove(name);
    await saveAllCategories(type, newList);
  }

  Future<void> editCategory(TransactionType type, String oldName, String newName) async {
    final current = getAllCategories(type);
    final index = current.indexOf(oldName);
    if (index != -1) {
      final newList = List<String>.from(current);
      newList[index] = newName;
      await saveAllCategories(type, newList);
    }
  }
  
  /// Syncs categories FROM sheet (downstream)
  Future<void> syncWithRemoteData(List<dynamic> expenses, List<dynamic> incomes) async {
    // Cast and save
    final expList = expenses.map((e) => e.toString()).toList();
    final incList = incomes.map((e) => e.toString()).toList();
    
    // Update local Hive but DO NOT push back to sheet (infinite loop/redundant)
    if (expList.isNotEmpty) await saveAllCategories(TransactionType.expense, expList, pushToRemote: false);
    if (incList.isNotEmpty) await saveAllCategories(TransactionType.income, incList, pushToRemote: false);
  }

  String _getKey(TransactionType type) {
    return type == TransactionType.expense ? 'custom_expense_categories' : 'custom_income_categories';
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final box = Hive.box('settings');
  final prefs = ref.watch(sharedPreferencesProvider);
  return CategoryRepository(box, prefs);
});
