class AppConfig {
  // API Configuration
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );
  static const String aiServiceUrl = 'http://localhost:8000/api';
  
  // API Endpoints
  static const String authEndpoint = '/auth';
  static const String expensesEndpoint = '/expenses';
  static const String incomesEndpoint = '/incomes';
  static const String budgetsEndpoint = '/budgets';
  static const String goalsEndpoint = '/goals';
  static const String reportsEndpoint = '/reports';
  static const String notificationsEndpoint = '/notifications';
  static const String voiceExpenseEndpoint = '/expenses/voice';
  static const String voicePreviewEndpoint = '/expenses/voice/preview';
  static const String voiceConfirmEndpoint = '/expenses/voice/confirm';
  static const String dashboardEndpoint = '/dashboard/summary';
  static const String insightsEndpoint        = '/reports/insights';
  static const String monthlyReportEndpoint   = '/reports/monthly';
  static const String recommendationsEndpoint = '/reports/recommendations';
  static const String walletEndpoint          = '/wallet';
  static const String parseTextEndpoint       = '/expenses/parse-text';
  static const String categoriesEndpoint      = '/categories';
  static const String userMeEndpoint          = '/user/me';
  static const String exportCsvEndpoint       = '/reports/export/csv';
  static const String exportPdfEndpoint       = '/reports/export/pdf';
  static const String forecastEndpointSpring  = '/reports/forecast';
  static const String benchmarksEndpoint      = '/reports/benchmarks';
  
  // AI Service Endpoints
  static const String speechToTextEndpoint = '/speech-to-text';
  static const String categorizeEndpoint = '/categorize';
  static const String forecastEndpoint = '/forecast';
  static const String recommendEndpoint = '/recommend';
  
  // App Configuration
  static const int apiTimeout = 30000; // 30 seconds
  static const int maxRetries = 3;
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
}
