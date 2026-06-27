import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/theme.dart';
import '../../../data/models/insights.dart';
import '../../providers/insights_provider.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<InsightsProvider>().loadInsights());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<InsightsProvider>().loadInsights(),
          ),
        ],
      ),
      body: Consumer<InsightsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('AI is analysing your finances...'),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.psychology_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('Could not load AI insights',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(provider.error!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => provider.loadInsights(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.insights == null) {
            return const Center(child: Text('No insights available'));
          }

          final ins = provider.insights!;
          return RefreshIndicator(
            onRefresh: () => provider.loadInsights(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ScoreCard(score: ins.overallScore),
                  const SizedBox(height: 20),

                  if (ins.patterns?.behavioral != null) ...[
                    _BehavioralChips(behavioral: ins.patterns!.behavioral!),
                    const SizedBox(height: 20),
                  ],

                  if (ins.forecast != null) ...[
                    const _SectionTitle('Forecast'),
                    const SizedBox(height: 12),
                    _ForecastCard(forecast: ins.forecast!),
                    const SizedBox(height: 20),
                  ],

                  if (ins.patterns != null &&
                      ins.patterns!.anomalies.isNotEmpty) ...[
                    const _SectionTitle('Spending Alerts'),
                    const SizedBox(height: 12),
                    _AlertsList(anomalies: ins.patterns!.anomalies),
                    const SizedBox(height: 20),
                  ],

                  if (ins.recommendations != null &&
                      ins.recommendations!.spendingInsights.isNotEmpty) ...[
                    const _SectionTitle('Overspending'),
                    const SizedBox(height: 12),
                    _OverspendingList(items: ins.recommendations!.spendingInsights),
                    const SizedBox(height: 20),
                  ],

                  if (ins.recommendations?.saving != null) ...[
                    const _SectionTitle('Savings Plan'),
                    const SizedBox(height: 12),
                    _SavingsCard(saving: ins.recommendations!.saving!),
                    const SizedBox(height: 20),
                  ],

                  if (ins.recommendations != null &&
                      ins.recommendations!.goalPlans.isNotEmpty) ...[
                    const _SectionTitle('Goal Plans'),
                    const SizedBox(height: 12),
                    _GoalPlansList(plans: ins.recommendations!.goalPlans),
                    const SizedBox(height: 20),
                  ],

                  if (ins.recommendations != null &&
                      ins.recommendations!.investments.isNotEmpty) ...[
                    const _SectionTitle('Investment Ideas'),
                    const SizedBox(height: 12),
                    _InvestmentsList(items: ins.recommendations!.investments),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) =>
      Text(title, style: Theme.of(context).textTheme.titleLarge);
}

// ── Financial Health Score ────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final int score;
  const _ScoreCard({required this.score});

  (Color, String) _grade(int s) {
    if (s >= 80) return (AppTheme.successColor, 'Excellent');
    if (s >= 65) return (AppTheme.secondaryColor, 'Good');
    if (s >= 50) return (AppTheme.warningColor, 'Fair');
    return (AppTheme.errorColor, 'Needs Attention');
  }

  @override
  Widget build(BuildContext context) {
    final (color, label) = _grade(score);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_outlined, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Financial Health Score',
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 12,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                          fontSize: 40, fontWeight: FontWeight.bold, color: color),
                    ),
                    Text('/100', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(label,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Behavioral Chips ──────────────────────────────────────────────────────────

class _BehavioralChips extends StatelessWidget {
  final BehavioralPatterns behavioral;
  const _BehavioralChips({required this.behavioral});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (behavioral.primarySpendingDay.isNotEmpty)
          _InfoChip(
            icon: Icons.calendar_today,
            label: 'Peak day: ${_capitalize(behavioral.primarySpendingDay)}',
          ),
        if (behavioral.primarySpendingCategory.isNotEmpty)
          _InfoChip(
            icon: Icons.category_outlined,
            label: 'Top category: ${behavioral.primarySpendingCategory}',
          ),
      ],
    );
  }

  String _capitalize(String s) => s.isEmpty
      ? s
      : s[0].toUpperCase() + s.substring(1).toLowerCase();
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ── Forecast ──────────────────────────────────────────────────────────────────

class _ForecastCard extends StatelessWidget {
  final ForecastInsight forecast;
  const _ForecastCard({required this.forecast});

  @override
  Widget build(BuildContext context) {
    final confPct = (forecast.confidence * 100).toStringAsFixed(0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          forecast.forecastMonth.isNotEmpty
                              ? 'Next month (${forecast.forecastMonth})'
                              : 'Next Month Expected',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text(
                        'EGP ${_fmt(forecast.totalPredicted)}',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold, fontSize: 26),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$confPct% confidence',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            if (forecast.byCategory.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text('By Category',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...forecast.byCategory.entries.take(6).map((e) {
                final isUp = e.value.trend.toUpperCase() == 'UP';
                final trendColor =
                    isUp ? AppTheme.errorColor : AppTheme.successColor;
                final pct = e.value.changePercentage;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                          isUp ? Icons.trending_up : Icons.trending_down,
                          size: 16,
                          color: trendColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(e.key,
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text(
                        'EGP ${_fmt(e.value.predicted)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${pct > 0 ? '+' : ''}${pct.toStringAsFixed(0)}%',
                        style: TextStyle(
                            fontSize: 11, color: trendColor, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  String _fmt(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}K' : v.toStringAsFixed(0);
}

// ── Spending Alerts ───────────────────────────────────────────────────────────

class _AlertsList extends StatelessWidget {
  final List<SpendingAnomaly> anomalies;
  const _AlertsList({required this.anomalies});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: anomalies.map((a) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      size: 18, color: AppTheme.warningColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(a.category,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text('EGP ${a.amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.warningColor)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(a.reason,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.darkTextSec)),
                      Text('Normal: EGP ${a.normalAmount.toStringAsFixed(0)}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppTheme.darkTextMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Overspending ──────────────────────────────────────────────────────────────

class _OverspendingList extends StatelessWidget {
  final List<SpendingInsight> items;
  const _OverspendingList({required this.items});

  @override
  Widget build(BuildContext context) {
    final sorted = [...items]
      ..sort((a, b) => b.percentageDiff.compareTo(a.percentageDiff));
    return Column(
      children: sorted.take(5).map((item) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.category,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '+${item.percentageDiff.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Current: EGP ${item.currentSpending.toStringAsFixed(0)}  ·  Avg: EGP ${item.averageSpending.toStringAsFixed(0)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppTheme.darkTextSec),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(item.recommendation,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppTheme.primaryColor)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Savings Plan ──────────────────────────────────────────────────────────────

class _SavingsCard extends StatelessWidget {
  final SavingRecommendations saving;
  const _SavingsCard({required this.saving});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.savings_outlined, color: AppTheme.successColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('EGP ${saving.monthlyTarget.toStringAsFixed(0)} / month',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _SavingBucket('Emergency', saving.emergencyFund, AppTheme.warningColor),
                const SizedBox(width: 8),
                _SavingBucket('Invest', saving.investments, AppTheme.primaryColor),
                const SizedBox(width: 8),
                _SavingBucket('Goals', saving.goals, AppTheme.successColor),
              ],
            ),
            if (saving.recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              ...saving.recommendations.take(3).map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 16, color: AppTheme.successColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(r,
                              style: Theme.of(context).textTheme.bodyMedium,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _SavingBucket extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _SavingBucket(this.label, this.amount, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              'EGP\n${amount.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Goal Plans ────────────────────────────────────────────────────────────────

class _GoalPlansList extends StatelessWidget {
  final List<GoalPlan> plans;
  const _GoalPlansList({required this.plans});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: plans.map((plan) {
        final (fColor, fLabel) = _feasibility(plan.feasibility);
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(plan.goalName,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: fColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(fLabel,
                          style: TextStyle(
                              fontSize: 11,
                              color: fColor,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: plan.progress,
                    minHeight: 6,
                    backgroundColor: AppTheme.darkElevated,
                    valueColor: AlwaysStoppedAnimation(fColor),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'EGP ${plan.currentAmount.toStringAsFixed(0)} / ${plan.targetAmount.toStringAsFixed(0)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppTheme.darkTextSec),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${plan.monthsToGoal}mo · EGP ${plan.monthlySavingRequired.toStringAsFixed(0)}/mo',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppTheme.darkTextSec, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  (Color, String) _feasibility(String f) {
    switch (f.toUpperCase()) {
      case 'EASY':
        return (AppTheme.successColor, 'Easy');
      case 'MODERATE':
        return (AppTheme.warningColor, 'Moderate');
      default:
        return (AppTheme.errorColor, 'Hard');
    }
  }
}

// ── Investment Ideas ──────────────────────────────────────────────────────────

class _InvestmentsList extends StatelessWidget {
  final List<InvestmentSuggestion> items;
  const _InvestmentsList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.trending_up,
                      size: 20, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(_formatType(item.type),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text('EGP ${item.suggestedAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.expectedReturn}  ·  Risk: ${item.riskLevel}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppTheme.darkTextSec),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(item.recommendation,
                          style: Theme.of(context).textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatType(String t) =>
      t.replaceAll('_', ' ').split(' ').map((w) {
        if (w.isEmpty) return w;
        return w[0].toUpperCase() + w.substring(1).toLowerCase();
      }).join(' ');
}
