class FinancialInsights {
  final ForecastData? forecast;
  final List<SpendingPattern> patterns;
  final List<String> recommendations;
  final double overallFinancialScore;

  FinancialInsights({
    this.forecast,
    required this.patterns,
    required this.recommendations,
    required this.overallFinancialScore,
  });

  factory FinancialInsights.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return FinancialInsights(
      forecast: data['forecast'] is Map
          ? ForecastData.fromJson(data['forecast'] as Map<String, dynamic>)
          : null,
      patterns: data['patterns'] is List
          ? (data['patterns'] as List)
              .whereType<Map<String, dynamic>>()
              .map(SpendingPattern.fromJson)
              .toList()
          : [],
      recommendations: data['recommendations'] is List
          ? (data['recommendations'] as List)
              .map((r) => r.toString())
              .toList()
          : [],
      overallFinancialScore:
          (data['overallFinancialScore'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ForecastData {
  final double nextMonthExpected;
  final double trend;
  final String trendDirection;
  final Map<String, double> categoryForecasts;

  ForecastData({
    required this.nextMonthExpected,
    required this.trend,
    required this.trendDirection,
    required this.categoryForecasts,
  });

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    final categoryMap = <String, double>{};
    if (json['categoryForecasts'] is Map) {
      (json['categoryForecasts'] as Map).forEach((k, v) {
        categoryMap[k.toString()] = (v as num).toDouble();
      });
    }
    return ForecastData(
      nextMonthExpected:
          (json['nextMonthExpected'] as num?)?.toDouble() ?? 0.0,
      trend: (json['trend'] as num?)?.toDouble() ?? 0.0,
      trendDirection: json['trendDirection']?.toString() ?? 'stable',
      categoryForecasts: categoryMap,
    );
  }
}

class SpendingPattern {
  final String category;
  final double averageAmount;
  final String frequency;
  final String insight;

  SpendingPattern({
    required this.category,
    required this.averageAmount,
    required this.frequency,
    required this.insight,
  });

  factory SpendingPattern.fromJson(Map<String, dynamic> json) {
    return SpendingPattern(
      category: json['category']?.toString() ?? '',
      averageAmount: (json['averageAmount'] as num?)?.toDouble() ?? 0.0,
      frequency: json['frequency']?.toString() ?? '',
      insight: json['insight']?.toString() ?? '',
    );
  }
}
