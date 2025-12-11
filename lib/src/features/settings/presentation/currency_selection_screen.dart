import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/providers/currency_provider.dart';

class CurrencySelectionScreen extends ConsumerStatefulWidget {
  const CurrencySelectionScreen({super.key});

  @override
  ConsumerState<CurrencySelectionScreen> createState() => _CurrencySelectionScreenState();
}

class _CurrencySelectionScreenState extends ConsumerState<CurrencySelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentCurrency = ref.watch(currencyProvider);
    
    final filteredCurrencies = kCurrencies.where((currency) {
      return currency.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Currency"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Search Currency",
                hintText: "e.g. USD, EUR",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredCurrencies.length,
              itemBuilder: (context, index) {
                final currency = filteredCurrencies[index];
                final isSelected = currency == currentCurrency;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor.withOpacity(0.1),
                    child: Text(
                      currency.substring(0, 1),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  title: Text(currency, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: isSelected ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor) : null,
                  onTap: () {
                    ref.read(currencyProvider.notifier).setCurrency(currency);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
