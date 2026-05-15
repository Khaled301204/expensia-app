class AppConstants {
  // App Info
  static const String appName = 'Expensia';
  static const String appTagline = 'AI-Powered Personal Finance Tracker';
  
  // Categories
  static const List<String> expenseCategories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Bills & Utilities',
    'Healthcare',
    'Education',
    'Travel',
    'Personal Care',
    'Other',
  ];
  
  // Payment Methods
  static const List<String> paymentMethods = [
    'Cash',
    'Credit Card',
    'Debit Card',
    'Bank Transfer',
    'Mobile Payment',
  ];
  
  // Risk Preferences
  static const List<String> riskPreferences = [
    'Low',
    'Medium',
    'High',
  ];
  
  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'MMM dd, yyyy';
  static const String displayDateTimeFormat = 'MMM dd, yyyy hh:mm a';
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxDescriptionLength = 500;
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Currency
  static const String currencySymbol = 'EGP';
  static const String currencyCode = 'EGP';
}
