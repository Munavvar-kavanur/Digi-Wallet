import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_provider.dart';

// Comprehensive list of currencies
const List<String> kCurrencies = [
  'USD', // US Dollar (United States)
  'EUR', // Euro (Eurozone)
  'GBP', // British Pound (United Kingdom)
  'INR', // Indian Rupee (India)
  'AED', // United Arab Emirates Dirham
  'AFN', // Afghan Afghani
  'ALL', // Albanian Lek
  'AMD', // Armenian Dram
  'ARS', // Argentine Peso
  'AUD', // Australian Dollar
  'AZN', // Azerbaijani Manat
  'BAM', // Bosnia-Herzegovina Convertible Mark
  'BDT', // Bangladeshi Taka
  'BGN', // Bulgarian Lev
  'BHD', // Bahraini Dinar
  'BRL', // Brazilian Real
  'BSD', // Bahamian Dollar
  'CAD', // Canadian Dollar
  'CHF', // Swiss Franc
  'CLP', // Chilean Peso
  'CNY', // Chinese Yuan
  'COP', // Colombian Peso
  'CRC', // Costa Rican Colón
  'CZK', // Czech Koruna
  'DKK', // Danish Krone
  'DOP', // Dominican Peso
  'DZD', // Algerian Dinar
  'EGP', // Egyptian Pound
  'ETB', // Ethiopian Birr
  'FJD', // Fijian Dollar
  'GEL', // Georgian Lari
  'GHS', // Ghanaian Cedi
  'HKD', // Hong Kong Dollar
  'HUF', // Hungarian Forint
  'IDR', // Indonesian Rupiah
  'ILS', // Israeli New Shekel
  'IQD', // Iraqi Dinar
  'ISK', // Icelandic Króna
  'JMD', // Jamaican Dollar
  'JOD', // Jordanian Dinar
  'JPY', // Japanese Yen
  'KES', // Kenyan Shilling
  'KHR', // Cambodian Riel
  'KRW', // South Korean Won
  'KWD', // Kuwaiti Dinar
  'KZT', // Kazakhstani Tenge
  'LBP', // Lebanese Pound
  'LKR', // Sri Lankan Rupee
  'MAD', // Moroccan Dirham
  'MMK', // Burmese Kyat
  'MXN', // Mexican Peso
  'MYR', // Malaysian Ringgit
  'NGN', // Nigerian Naira
  'NOK', // Norwegian Krone
  'NPR', // Nepalese Rupee
  'NZD', // New Zealand Dollar
  'OMR', // Omani Rial
  'PAB', // Panamanian Balboa
  'PEN', // Peruvian Sol
  'PHP', // Philippine Peso
  'PKR', // Pakistani Rupee
  'PLN', // Polish Złoty
  'QAR', // Qatari Riyal
  'RON', // Romanian Leu
  'RSD', // Serbian Dinar
  'RUB', // Russian Ruble
  'SAR', // Saudi Riyal
  'SEK', // Swedish Krona
  'SGD', // Singapore Dollar
  'THB', // Thai Baht
  'TND', // Tunisian Dinar
  'TRY', // Turkish Lira
  'TWD', // New Taiwan Dollar
  'UAH', // Ukrainian Hryvnia
  'UGX', // Ugandan Shilling
  'VEF', // Venezuelan Bolívar
  'VND', // Vietnamese Dong
  'XAF', // Central African CFA Franc
  'XOF', // West African CFA Franc
  'ZAR', // South African Rand
];

const Map<String, String> kCurrencySymbols = {
  'USD': '\$',
  'EUR': '€',
  'GBP': '£',
  'INR': '₹',
  'AED': 'AED',
  'AFN': '؋',
  'ALL': 'L',
  'AMD': '֏',
  'ARS': '\$',
  'AUD': 'A\$',
  'AZN': '₼',
  'BAM': 'KM',
  'BDT': '৳',
  'BGN': 'лв',
  'BHD': '.د.ب', 
  'BRL': 'R\$',
  'BSD': '\$',
  'CAD': 'CA\$',
  'CHF': 'Fr',
  'CLP': '\$',
  'CNY': '¥',
  'COP': '\$',
  'CRC': '₡',
  'CZK': 'Kč',
  'DKK': 'kr',
  'DOP': 'RD\$',
  'DZD': 'د.ج',
  'EGP': 'E£',
  'ETB': 'Br',
  'FJD': '\$',
  'GEL': '₾',
  'GHS': 'GH₵',
  'HKD': 'HK\$',
  'HUF': 'Ft',
  'IDR': 'Rp',
  'ILS': '₪',
  'IQD': 'ع.د',
  'ISK': 'kr',
  'JMD': 'J\$',
  'JOD': 'د.ا',
  'JPY': '¥',
  'KES': 'KSh',
  'KHR': '៛',
  'KRW': '₩',
  'KWD': 'د.ك',
  'KZT': '₸',
  'LBP': 'L£',
  'LKR': 'Rs',
  'MAD': 'DH',
  'MMK': 'Ks',
  'MXN': '\$',
  'MYR': 'RM',
  'NGN': '₦',
  'NOK': 'kr',
  'NPR': 'Rs',
  'NZD': 'NZ\$',
  'OMR': 'ر.ع.',
  'PAB': 'B/.',
  'PEN': 'S/',
  'PHP': '₱',
  'PKR': 'Rs',
  'PLN': 'zł',
  'QAR': 'ر.ق',
  'RON': 'lei',
  'RSD': 'дин.',
  'RUB': '₽',
  'SAR': 'ر.س',
  'SEK': 'kr',
  'SGD': 'S\$',
  'THB': '฿',
  'TND': 'د.ت',
  'TRY': '₺',
  'TWD': 'NT\$',
  'UAH': '₴',
  'UGX': 'USh',
  'VEF': 'Bs',
  'VND': '₫',
  'XAF': 'FCFA',
  'XOF': 'CFA',
  'ZAR': 'R',
};

final currencySymbolProvider = Provider<String>((ref) {
  final code = ref.watch(currencyProvider);
  return kCurrencySymbols[code] ?? code;
});

final currencyProvider = StateNotifierProvider<CurrencyNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CurrencyNotifier(prefs);
});

class CurrencyNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;
  static const _key = 'currency_code';

  CurrencyNotifier(this._prefs) : super(_loadCurrency(_prefs));

  static String _loadCurrency(SharedPreferences prefs) {
    return prefs.getString(_key) ?? 'USD';
  }

  Future<void> setCurrency(String currencyCode) async {
    state = currencyCode;
    await _prefs.setString(_key, currencyCode);
  }
}
