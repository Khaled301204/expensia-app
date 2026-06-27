class FinancialInsights {
  final int overallScore;
  final ForecastInsight? forecast;
  final PatternsInsight? patterns;
  final RecommendationsInsight? recommendations;

  const FinancialInsights({
    required this.overallScore,
    this.forecast,
    this.patterns,
    this.recommendations,
  });

  factory FinancialInsights.fromJson(Map<String, dynamic> json) {
    final rawRec = json['recommendations'];
    final recMap = rawRec is Map ? Map<String, dynamic>.from(rawRec) : null;
    return FinancialInsights(
      overallScore: (recMap?['overall_score'] as num?)?.toInt() ?? 0,
      forecast: json['forecast'] is Map
          ? ForecastInsight.fromJson(Map<String, dynamic>.from(json['forecast'] as Map))
          : null,
      patterns: json['patterns'] is Map
          ? PatternsInsight.fromJson(Map<String, dynamic>.from(json['patterns'] as Map))
          : null,
      recommendations: recMap != null ? RecommendationsInsight.fromJson(recMap) : null,
    );
  }
}

// ── Forecast ───────────────────────────────────────────────────────────────────

class ForecastInsight {
  final double totalPredicted;
  final Map<String, CategoryForecast> byCategory;
  final double confidence;
  final String forecastMonth;

  const ForecastInsight({
    required this.totalPredicted,
    required this.byCategory,
    required this.confidence,
    required this.forecastMonth,
  });

  factory ForecastInsight.fromJson(Map<String, dynamic> json) {
    final map = <String, CategoryForecast>{};
    if (json['by_category'] is Map) {
      (json['by_category'] as Map).forEach((k, v) {
        if (v is Map) map[k.toString()] = CategoryForecast.fromJson(Map<String, dynamic>.from(v));
      });
    }
    return ForecastInsight(
      totalPredicted: (json['total_predicted'] as num?)?.toDouble() ?? 0,
      byCategory: map,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      forecastMonth: json['forecast_month']?.toString() ?? '',
    );
  }
}

class CategoryForecast {
  final double predicted;
  final double currentMonth;
  final String trend; // UP / DOWN
  final double changePercentage;

  const CategoryForecast({
    required this.predicted,
    required this.currentMonth,
    required this.trend,
    required this.changePercentage,
  });

  factory CategoryForecast.fromJson(Map<String, dynamic> json) {
    return CategoryForecast(
      predicted: (json['predicted'] as num?)?.toDouble() ?? 0,
      currentMonth: (json['current_month'] as num?)?.toDouble() ?? 0,
      trend: json['trend']?.toString() ?? 'STABLE',
      changePercentage: (json['change_percentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ── Patterns ───────────────────────────────────────────────────────────────────

class PatternsInsight {
  final TemporalPatterns? temporal;
  final BehavioralPatterns? behavioral;
  final List<SpendingAnomaly> anomalies;

  const PatternsInsight({
    this.temporal,
    this.behavioral,
    required this.anomalies,
  });

  factory PatternsInsight.fromJson(Map<String, dynamic> json) {
    final seen = <String>{};
    final anomalies = <SpendingAnomaly>[];
    if (json['anomalies'] is List) {
      for (final raw in json['anomalies'] as List) {
        if (raw is Map) {
          final a = SpendingAnomaly.fromJson(Map<String, dynamic>.from(raw));
          if (seen.add('${a.date}_${a.category}_${a.amount}')) anomalies.add(a);
        }
      }
    }
    return PatternsInsight(
      temporal: json['temporal_patterns'] is Map
          ? TemporalPatterns.fromJson(Map<String, dynamic>.from(json['temporal_patterns'] as Map))
          : null,
      behavioral: json['behavioral_patterns'] is Map
          ? BehavioralPatterns.fromJson(Map<String, dynamic>.from(json['behavioral_patterns'] as Map))
          : null,
      anomalies: anomalies,
    );
  }
}

class TemporalPatterns {
  final double weekdayAverage;
  final double weekendAverage;
  final double earlyMonthAverage;
  final double lateMonthAverage;

  const TemporalPatterns({
    required this.weekdayAverage,
    required this.weekendAverage,
    required this.earlyMonthAverage,
    required this.lateMonthAverage,
  });

  factory TemporalPatterns.fromJson(Map<String, dynamic> json) {
    return TemporalPatterns(
      weekdayAverage: (json['weekday_average'] as num?)?.toDouble() ?? 0,
      weekendAverage: (json['weekend_average'] as num?)?.toDouble() ?? 0,
      earlyMonthAverage: (json['early_month_average'] as num?)?.toDouble() ?? 0,
      lateMonthAverage: (json['late_month_average'] as num?)?.toDouble() ?? 0,
    );
  }
}

class BehavioralPatterns {
  final String primarySpendingDay;
  final String primarySpendingCategory;

  const BehavioralPatterns({
    required this.primarySpendingDay,
    required this.primarySpendingCategory,
  });

  factory BehavioralPatterns.fromJson(Map<String, dynamic> json) {
    return BehavioralPatterns(
      primarySpendingDay: json['primary_spending_day']?.toString() ?? '',
      primarySpendingCategory: json['primary_spending_category']?.toString() ?? '',
    );
  }
}

class SpendingAnomaly {
  final String date;
  final String category;
  final double amount;
  final double normalAmount;
  final String reason;

  const SpendingAnomaly({
    required this.date,
    required this.category,
    required this.amount,
    required this.normalAmount,
    required this.reason,
  });

  factory SpendingAnomaly.fromJson(Map<String, dynamic> json) {
    return SpendingAnomaly(
      date: json['date']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      normalAmount: (json['normal_amount'] as num?)?.toDouble() ?? 0,
      reason: json['reason']?.toString() ?? '',
    );
  }
}

// ── Recommendations ────────────────────────────────────────────────────────────

class RecommendationsInsight {
  final List<SpendingInsight> spendingInsights;
  final SavingRecommendations? saving;
  final List<InvestmentSuggestion> investments;
  final List<GoalPlan> goalPlans;

  const RecommendationsInsight({
    required this.spendingInsights,
    this.saving,
    required this.investments,
    required this.goalPlans,
  });

  factory RecommendationsInsight.fromJson(Map<String, dynamic> json) {
    return RecommendationsInsight(
      spendingInsights: json['spending_insights'] is List
          ? (json['spending_insights'] as List)
              .whereType<Map>()
              .map((e) => SpendingInsight.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [],
      saving: json['saving_recommendations'] is Map
          ? SavingRecommendations.fromJson(
              Map<String, dynamic>.from(json['saving_recommendations'] as Map))
          : null,
      investments: json['investment_suggestions'] is List
          ? (json['investment_suggestions'] as List)
              .whereType<Map>()
              .map((e) => InvestmentSuggestion.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [],
      goalPlans: json['goal_plans'] is List
          ? (json['goal_plans'] as List)
              .whereType<Map>()
              .map((e) => GoalPlan.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [],
    );
  }
}

class SpendingInsight {
  final String category;
  final double currentSpending;
  final double averageSpending;
  final double percentageDiff;
  final String recommendation;

  const SpendingInsight({
    required this.category,
    required this.currentSpending,
    required this.averageSpending,
    required this.percentageDiff,
    required this.recommendation,
  });

  factory SpendingInsight.fromJson(Map<String, dynamic> json) {
    return SpendingInsight(
      category: json['category']?.toString() ?? '',
      currentSpending: (json['current_spending'] as num?)?.toDouble() ?? 0,
      averageSpending: (json['average_spending'] as num?)?.toDouble() ?? 0,
      percentageDiff: (json['percentage_diff'] as num?)?.toDouble() ?? 0,
      recommendation: json['recommendation']?.toString() ?? '',
    );
  }
}

class SavingRecommendations {
  final double monthlyTarget;
  final double emergencyFund;
  final double investments;
  final double goals;
  final List<String> recommendations;

  const SavingRecommendations({
    required this.monthlyTarget,
    required this.emergencyFund,
    required this.investments,
    required this.goals,
    required this.recommendations,
  });

  factory SavingRecommendations.fromJson(Map<String, dynamic> json) {
    final bd = json['breakdown'] is Map
        ? Map<String, dynamic>.from(json['breakdown'] as Map)
        : <String, dynamic>{};
    return SavingRecommendations(
      monthlyTarget: (json['monthly_target'] as num?)?.toDouble() ?? 0,
      emergencyFund: (bd['emergency_fund'] as num?)?.toDouble() ?? 0,
      investments: (bd['investments'] as num?)?.toDouble() ?? 0,
      goals: (bd['goals'] as num?)?.toDouble() ?? 0,
      recommendations: json['recommendations'] is List
          ? (json['recommendations'] as List).map((e) => e.toString()).toList()
          : [],
    );
  }
}

class InvestmentSuggestion {
  final String type;
  final double suggestedAmount;
  final String expectedReturn;
  final String riskLevel;
  final String recommendation;

  const InvestmentSuggestion({
    required this.type,
    required this.suggestedAmount,
    required this.expectedReturn,
    required this.riskLevel,
    required this.recommendation,
  });

  factory InvestmentSuggestion.fromJson(Map<String, dynamic> json) {
    return InvestmentSuggestion(
      type: json['type']?.toString() ?? '',
      suggestedAmount: (json['suggested_amount'] as num?)?.toDouble() ?? 0,
      expectedReturn: json['expected_return']?.toString() ?? '',
      riskLevel: json['risk_level']?.toString() ?? '',
      recommendation: json['recommendation']?.toString() ?? '',
    );
  }
}

class GoalPlan {
  final String goalName;
  final double targetAmount;
  final double currentAmount;
  final double monthlySavingRequired;
  final int monthsToGoal;
  final String feasibility; // EASY / MODERATE / HARD
  final String recommendation;

  const GoalPlan({
    required this.goalName,
    required this.targetAmount,
    required this.currentAmount,
    required this.monthlySavingRequired,
    required this.monthsToGoal,
    required this.feasibility,
    required this.recommendation,
  });

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0;

  factory GoalPlan.fromJson(Map<String, dynamic> json) {
    return GoalPlan(
      goalName: json['goal_name']?.toString() ?? '',
      targetAmount: (json['target_amount'] as num?)?.toDouble() ?? 0,
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0,
      monthlySavingRequired: (json['monthly_saving_required'] as num?)?.toDouble() ?? 0,
      monthsToGoal: (json['months_to_goal'] as num?)?.toInt() ?? 0,
      feasibility: json['feasibility']?.toString() ?? '',
      recommendation: json['recommendation']?.toString() ?? '',
    );
  }
}
