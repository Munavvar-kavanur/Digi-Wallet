import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../common/providers/theme_provider.dart';
import 'package:http/http.dart' as http;
import '../../transactions/domain/transaction_model.dart';
import '../data/category_repository.dart';
import '../../../common/providers/currency_provider.dart';
import 'dart:convert';

class GoogleSheetSettingsScreen extends ConsumerStatefulWidget {
  const GoogleSheetSettingsScreen({super.key});

  @override
  ConsumerState<GoogleSheetSettingsScreen> createState() => _GoogleSheetSettingsScreenState();
}

class _GoogleSheetSettingsScreenState extends ConsumerState<GoogleSheetSettingsScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isTesting = false;
  String? _statusMessage;
  Color _statusColor = Colors.grey;

  static const String _appsScriptCode = r'''
function doGet(e) {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheets()[0]; // Default: First sheet is transactions
  var rows = sheet.getDataRange().getValues();
  var data = [];
  
  for (var i = 1; i < rows.length; i++) {
    var row = rows[i];
    if(!row[0]) continue; 
    data.push({
      'id': row[0].toString(),
      'date': row[1],
      'amount': row[2],
      'category': row[3],
      'type': row[4],
      'note': row[5]
    });
  }
  
  // Fetch Categories
  var catSheet = ss.getSheetByName("Categories");
  var expenses = [];
  var incomes = [];
  
  if (catSheet) {
     var catRows = catSheet.getDataRange().getValues();
     // Column A (0) = Expense, Column B (1) = Income
     for(var i=1; i<catRows.length; i++) {
        var row = catRows[i];
        if (row.length > 0 && row[0] && row[0].toString() !== "") expenses.push(row[0].toString());
        if (row.length > 1 && row[1] && row[1].toString() !== "") incomes.push(row[1].toString());
     }
  }

  // Fetch Settings (Currency, etc.)
  var settingsSheet = ss.getSheetByName("Settings");
  var settings = {};
  
  if (settingsSheet) {
    var setRows = settingsSheet.getDataRange().getValues();
    for (var i = 1; i < setRows.length; i++) {
       var row = setRows[i];
       if (row.length > 1 && row[0]) {
         settings[row[0].toString()] = row[1].toString();
       }
    }
  }
  
  return ContentService.createTextOutput(JSON.stringify({
    'status': 'success', 
    'data': data,
    'categories': {
      'expense': expenses,
      'income': incomes
    },
    'settings': settings
  })).setMimeType(ContentService.MimeType.JSON);
}

function doPost(e) {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheets()[0]; // Default to first sheet for transactions
  
  var json = JSON.parse(e.postData.contents);
  var action = json.action;
  
  if (action == 'add') {
    var d = json.data;
    var newId = new Date().getTime().toString(); 
    sheet.appendRow([newId, d.date, d.amount, d.category, d.type, d.note]);
    return ContentService.createTextOutput(JSON.stringify({'status': 'success', 'id': newId})).setMimeType(ContentService.MimeType.JSON);
  }
  
  if (action == 'delete') {
    var id = json.id;
    var rows = sheet.getDataRange().getValues();
    for (var i = 1; i < rows.length; i++) {
      if (rows[i][0].toString() == id.toString()) {
        sheet.deleteRow(i + 1);
        return ContentService.createTextOutput(JSON.stringify({'status': 'success'})).setMimeType(ContentService.MimeType.JSON);
      }
    }
    return ContentService.createTextOutput(JSON.stringify({'status': 'error', 'message': 'ID not found'})).setMimeType(ContentService.MimeType.JSON);
  }

  if (action == 'edit') {
    var id = json.id;
    var d = json.data;
    var rows = sheet.getDataRange().getValues();
    for (var i = 1; i < rows.length; i++) {
      if (rows[i][0].toString() == id.toString()) {
        var range = sheet.getRange(i + 1, 1, 1, 6); 
        range.setValues([[id, d.date, d.amount, d.category, d.type, d.note]]);
        return ContentService.createTextOutput(JSON.stringify({'status': 'success'})).setMimeType(ContentService.MimeType.JSON);
      }
    }
  }

  if (action == 'updateCategory') {
     var oldName = json.oldName;
     var newName = json.newName;
     var rows = sheet.getDataRange().getValues();
     for (var i = 1; i < rows.length; i++) {
       if (rows[i][3] == oldName) {
         sheet.getRange(i + 1, 4).setValue(newName);
       }
     }
     return ContentService.createTextOutput(JSON.stringify({'status': 'success'})).setMimeType(ContentService.MimeType.JSON);
  }

  if (action == 'saveCategories') {
     var catSheet = ss.getSheetByName("Categories");
     if (!catSheet) {
       catSheet = ss.insertSheet("Categories");
       catSheet.appendRow(["Expense Categories", "Income Categories"]);
     }
     
     var type = json.type; 
     var categories = json.categories;
     var col = (type == 'expense') ? 1 : 2;
     
     var lastRow = catSheet.getLastRow();
     if (lastRow > 1) {
        catSheet.getRange(2, col, lastRow - 1, 1).clearContent();
     }
     
     if (categories.length > 0) {
       var values = categories.map(function(c) { return [c]; });
       catSheet.getRange(2, col, values.length, 1).setValues(values);
     }
     
     return ContentService.createTextOutput(JSON.stringify({'status': 'success'})).setMimeType(ContentService.MimeType.JSON);
  }

  if (action == 'saveSettings') {
     var settingsSheet = ss.getSheetByName("Settings");
     if (!settingsSheet) {
       settingsSheet = ss.insertSheet("Settings");
       settingsSheet.appendRow(["Key", "Value"]);
     }
     
     var settings = json.settings; // { "currency": "USD", ... }
     var keys = Object.keys(settings);
     var rows = settingsSheet.getDataRange().getValues();
     
     for (var k = 0; k < keys.length; k++) {
        var key = keys[k];
        var val = settings[key];
        var found = false;
        
        // Update existing
        for (var i = 1; i < rows.length; i++) {
           if (rows[i][0] == key) {
              settingsSheet.getRange(i + 1, 2).setValue(val);
              found = true;
              break;
           }
        }
        
        // Append new
        if (!found) {
           settingsSheet.appendRow([key, val]);
        }
     }
     return ContentService.createTextOutput(JSON.stringify({'status': 'success'})).setMimeType(ContentService.MimeType.JSON);
  }

  return ContentService.createTextOutput(JSON.stringify({'status': 'error', 'message': 'Invalid action'})).setMimeType(ContentService.MimeType.JSON);
}
''';

  @override
  void initState() {
    super.initState();
    // Load saved URL
    final prefs = ref.read(sharedPreferencesProvider);
    _urlController.text = prefs.getString('google_sheet_url') ?? '';
  }

  Future<void> _saveUrl() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final url = _urlController.text.trim().replaceAll(RegExp(r'\s+'), ''); // Clean spaces
    await prefs.setString('google_sheet_url', url);
    
    if (url.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
           content: Text("Connecting & Syncing data..."),
           behavior: SnackBarBehavior.floating,
           duration: Duration(seconds: 1),
        ));
      }

      // TWO-WAY SYNC LOGIC
      // 1. Try to PULL configuration from Sheet first (Sheet is Master if data exists)
      final pulled = await _pullConfiguration(url);
      
      // 2. If we didn't find any config on the sheet (it's likely new), PUSH our local config
      if (!pulled) {
         if(mounted) debugPrint("Sheet appears new, pushing local config...");
         await _forcePushCategories();
         await _syncSettings(url);
      } else {
         if(mounted) debugPrint("Config pulled from Sheet.");
      }
    }
    
    // Explicit success
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
         content: Text("Setup Complete: Connected & Synced!"),
         behavior: SnackBarBehavior.floating,
         backgroundColor: Colors.green,
      ));
    }
  }

  /// Returns true if configuration was successfully pulled and found on the sheet
  Future<bool> _pullConfiguration(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return false;

      final json = jsonDecode(response.body);
      bool foundData = false;

      // 1. Parse Settings (Currency)
      if (json['settings'] != null) {
        final settings = json['settings'];
        if (settings['currency'] != null) {
          final String sheetCurrency = settings['currency'].toString();
          ref.read(currencyProvider.notifier).setCurrency(sheetCurrency);
          foundData = true;
        }
      }

      // 2. Parse Categories
      if (json['categories'] != null) {
        final categories = json['categories'];
        final List<dynamic>? expenses = categories['expense'];
        final List<dynamic>? incomes = categories['income'];

        if ((expenses != null && expenses.isNotEmpty) || (incomes != null && incomes.isNotEmpty)) {
           await ref.read(categoryRepositoryProvider).syncWithRemoteData(
             expenses ?? [], 
             incomes ?? []
           );
           foundData = true;
        }
      }

      return foundData;

    } catch (e) {
      debugPrint("Pull Config Failed: $e");
      return false;
    }
  }

  Future<void> _forcePushCategories() async {
     try {
       final catRepo = ref.read(categoryRepositoryProvider);
       // Push Expenses
       final expenses = catRepo.getAllCategories(TransactionType.expense);
       await catRepo.saveAllCategories(TransactionType.expense, expenses);
       
       // Push Incomes
       final incomes = catRepo.getAllCategories(TransactionType.income);
       await catRepo.saveAllCategories(TransactionType.income, incomes);
       
     } catch(e) {
       debugPrint("Failed to force push categories: $e");
     }
  }

  Future<void> _syncSettings(String url) async {
    try {
      final currency = ref.read(currencyProvider);
      
      final body = jsonEncode({
        "action": "saveSettings",
        "settings": {
          "currency": currency
        }
      });
      
      await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      debugPrint("Settings synced successfully");
    } catch (e) {
      debugPrint("Failed to sync settings: $e");
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _statusMessage = "Ping...";
      _statusColor = Colors.blue;
    });

    final url = _urlController.text.trim().replaceAll(RegExp(r'\s+'), '');
    if (url.isEmpty) {
      setState(() {
        _isTesting = false;
        _statusMessage = "Please enter a URL first";
        _statusColor = Colors.red;
      });
      return;
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          _statusMessage = "Online - ${response.body.length} bytes loaded";
          _statusColor = Colors.green;
        });
      } else {
         setState(() {
          _statusMessage = "Error ${response.statusCode}";
          if (response.statusCode == 403) {
             _statusMessage = "Error 403: Check 'Who has access'";
          }
          _statusColor = Colors.red;
        });
      }
    } catch (e) {
       setState(() {
          _statusMessage = "Failed: $e";
          _statusColor = Colors.red;
        });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text("Google Sheets Sync", style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade700, Colors.teal.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                 const SizedBox(height: 8),
                 Text(
                   "Sync your finances with your own Google Sheet. You own your data.",
                   style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
                 ),
                 const SizedBox(height: 32),

                 // Step 1
                 _buildStepCard(
                   context, 
                   step: 1, 
                   title: "Create Apps Script", 
                   content: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text("1. Create a Google Sheet"),
                       const Text("2. Extensions > Apps Script"),
                       const Text("3. Paste this code and Save:"),
                       const SizedBox(height: 12),
                       Container(
                         height: 150,
                         width: double.infinity,
                         decoration: BoxDecoration(
                           color: const Color(0xFF1E1E1E), // Code background
                           borderRadius: BorderRadius.circular(8),
                         ),
                         child: Stack(
                           children: [
                             SingleChildScrollView(
                               padding: const EdgeInsets.all(12),
                               child: Text(
                                 _appsScriptCode, 
                                 style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFFD4D4D4))
                               ),
                             ),
                             Positioned(
                               top: 8, right: 8,
                               child: Material(
                                 color: Colors.white.withOpacity(0.1),
                                 borderRadius: BorderRadius.circular(4),
                                 child: InkWell(
                                   onTap: () {
                                     Clipboard.setData(const ClipboardData(text: _appsScriptCode));
                                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Code Copied!")));
                                   },
                                   borderRadius: BorderRadius.circular(4),
                                   child: const Padding(
                                     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                     child: Text("COPY", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                   ),
                                 ),
                               ),
                             )
                           ],
                         ),
                       ),
                     ],
                   )
                 ),

                 const SizedBox(height: 24),
                 
                 // Step 2
                 _buildStepCard(
                   context, 
                   step: 2, 
                   title: "Deploy Web App", 
                   content: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("1. Click Deploy > New Deployment"),
                        Text("2. Type: 'Web App'"),
                        Text("3. Who has access: 'Anyone' (Required)"),
                        Text("4. Deploy and Copy URL"),
                      ],
                   )
                 ),

                 const SizedBox(height: 24),

                 // Step 3
                 _buildStepCard(
                   context, 
                   step: 3, 
                   title: "Connect App", 
                   content: Column(
                     children: [
                       TextField(
                         controller: _urlController,
                         decoration: InputDecoration(
                           labelText: "Web App URL",
                           hintText: "https://script.google.com/...",
                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                           prefixIcon: const Icon(Icons.link),
                         ),
                       ),
                       const SizedBox(height: 16),
                       Row(
                         children: [
                           Expanded(
                             child: FilledButton.icon(
                               onPressed: _saveUrl,
                               style: FilledButton.styleFrom(
                                 padding: const EdgeInsets.symmetric(vertical: 16),
                                 backgroundColor: Colors.green.shade600,
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                               ),
                               icon: const Icon(Icons.cloud_sync_rounded), 
                               label: const Text("Save & Sync")
                             ),
                           ),
                           const SizedBox(width: 8),
                           IconButton.filledTonal(
                             onPressed: _isTesting ? null : _testConnection,
                             icon: _isTesting 
                               ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                               : (_statusColor == Colors.green ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.wifi_find)),
                             tooltip: "Test Connection",
                             style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.all(16)),
                           )
                         ],
                       ),
                       if (_statusMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _statusColor.withOpacity(0.3))
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.info_outline, size: 16, color: _statusColor),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_statusMessage!, style: TextStyle(color: _statusColor, fontWeight: FontWeight.bold, fontSize: 13))),
                                ],
                              ),
                            ),
                          )
                     ],
                   )
                 ),
                 
                 const SizedBox(height: 48),
              ]),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStepCard(BuildContext context, {required int step, required String title, required Widget content}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             children: [
               Container(
                 width: 28, height: 28,
                 alignment: Alignment.center,
                 decoration: BoxDecoration(
                   color: Theme.of(context).primaryColor,
                   shape: BoxShape.circle
                 ),
                 child: Text(step.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
               ),
               const SizedBox(width: 12),
               Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
             ],
           ),
           const Divider(height: 32),
           content,
        ],
      ),
    );
  }
}
