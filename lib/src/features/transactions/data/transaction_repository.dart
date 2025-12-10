import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../common/providers/theme_provider.dart';
import '../domain/transaction_model.dart';
import 'package:flutter/foundation.dart'; // for debugPrint

class TransactionRepository {
  final Box<Transaction> _box;
  final SharedPreferences _prefs;

  TransactionRepository(this._box, this._prefs);

  String? get _sheetUrl => _prefs.getString('google_sheet_url')?.trim().replaceAll(RegExp(r'\s+'), '');

  /// Always returns local Hive data instantly (Local First)
  Future<List<Transaction>> getTransactions() async {
    return _box.values.toList();
  }

  /// Fetches raw JSON data from the Sheet (Transactions + Categories)
  Future<Map<String, dynamic>?> fetchFullData() async {
    final url = _sheetUrl;
    if (url == null || url.isEmpty) return null;

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
    } catch (e) {
       debugPrint("Fetch Error: $e");
       rethrow;
    }
    return null;
  }

  /// Updates local Hive DB with remote transaction list
  Future<void> syncLocalData(List<dynamic> remoteList) async {
       final remoteTransactions = remoteList.map((e) => Transaction.fromJson(e)).toList();
       
       await _box.clear();
       await _box.addAll(remoteTransactions);
       debugPrint("Synced ${remoteTransactions.length} transactions.");
  }

  /// Legacy wrapper for backward compatibility if needed, using new methods
  Future<void> syncWithSheet() async {
     final data = await fetchFullData();
     if (data != null && data.containsKey('data')) {
       final list = data['data'];
       if (list is List) {
          await syncLocalData(list);
       }
     }
  }

  Future<void> addTransaction(Transaction transaction) async {
    // 1. Local Write (Optimistic)
    await _box.add(transaction);

    // 2. Remote Push (Background - Fire and Forget)
    final url = _sheetUrl;
    if (url != null && url.isNotEmpty) {
       // Do not await. Let it run in background.
       http.post(
           Uri.parse(url),
           body: jsonEncode({
             'action': 'add',
             'data': transaction.toJson(),
           }),
         ).then((_) => debugPrint("Background Push Success"))
          .catchError((e) => debugPrint("Background Push Failed: $e"));
    }
  }

  Future<void> deleteTransaction(dynamic key) async {
    // Hive key might not match Sheet ID if we did a full replace.
    // We need to find the ID of the transaction before deleting.
    final transaction = _box.get(key);
    final id = transaction?.id;

    await _box.delete(key);

    final url = _sheetUrl;
    if (url != null && url.isNotEmpty && id != null) {
       http.post(
           Uri.parse(url),
           body: jsonEncode({
             'action': 'delete',
             'id': id,
           }),
         ).catchError((e) => debugPrint("Background Delete Failed: $e"));
    }
  }

  Future<void> editTransaction(dynamic key, Transaction transaction) async {
    await _box.put(key, transaction);

    final url = _sheetUrl;
    if (url != null && url.isNotEmpty && transaction.id != null) {
       http.post(
           Uri.parse(url),
           body: jsonEncode({
             'action': 'edit',
             'id': transaction.id,
             'data': transaction.toJson(),
           }),
         ).catchError((e) => debugPrint("Background Edit Failed: $e"));
    }
  }

  Future<void> updateCategoryName(String oldName, String newName) async {
      final transactions = _box.values.toList();
      final keys = _box.keys.toList();
    
      // Local Update
      for (var i = 0; i < transactions.length; i++) {
        final transaction = transactions[i];
        if (transaction.category == oldName) {
          final updatedTransaction = Transaction(
            amount: transaction.amount,
            category: newName, 
            date: transaction.date,
            note: transaction.note,
            type: transaction.type,
            id: transaction.id,
          );
          await _box.put(keys[i], updatedTransaction);
        }
      }

      // Remote Update (Background)
      final url = _sheetUrl;
      if (url != null && url.isNotEmpty) {
           http.post(
             Uri.parse(url),
             body: jsonEncode({
               'action': 'updateCategory',
               'oldName': oldName,
               'newName': newName,
             }),
           ).catchError((e) => debugPrint("Background Cat Update Failed: $e"));
      }
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final box = Hive.box<Transaction>('transactions');
  final prefs = ref.watch(sharedPreferencesProvider);
  return TransactionRepository(box, prefs);
});
