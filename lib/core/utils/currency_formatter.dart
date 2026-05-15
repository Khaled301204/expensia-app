import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class CurrencyFormatter {
  static String format(double amount, {bool showSymbol = true}) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    final formattedAmount = formatter.format(amount);
    return showSymbol ? '${AppConstants.currencySymbol} $formattedAmount' : formattedAmount;
  }
  
  static String formatCompact(double amount, {bool showSymbol = true}) {
    String formatted;
    if (amount >= 1000000) {
      formatted = '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      formatted = '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      formatted = amount.toStringAsFixed(0);
    }
    return showSymbol ? '${AppConstants.currencySymbol} $formatted' : formatted;
  }
  
  static double? parse(String amountString) {
    try {
      // Remove currency symbol and commas
      final cleanString = amountString
          .replaceAll(AppConstants.currencySymbol, '')
          .replaceAll(',', '')
          .trim();
      return double.parse(cleanString);
    } catch (e) {
      return null;
    }
  }
  
  static String formatWithSign(double amount, {bool showSymbol = true}) {
    final sign = amount >= 0 ? '+' : '';
    return '$sign${format(amount, showSymbol: showSymbol)}';
  }
}
