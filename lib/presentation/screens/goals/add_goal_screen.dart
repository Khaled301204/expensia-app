import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/goal_provider.dart';
import '../../providers/wallet_provider.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _initialController = TextEditingController();
  DateTime _deadline = DateTime.now().add(const Duration(days: 90));

  @override
  void initState() {
    super.initState();
    _targetController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<WalletProvider>().loadWallet());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _initialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletSavings = context.watch<WalletProvider>().savings;

    return Scaffold(
      appBar: AppBar(title: const Text('New Savings Goal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label(context, 'Goal Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Emergency Fund, Vacation, New Laptop',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a goal name' : null,
              ),
              const SizedBox(height: 20),

              _label(context, 'Target Amount (EGP)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _targetController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  prefixText: 'EGP  ',
                  hintText: '0.00',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter a target amount';
                  final val = double.tryParse(v.trim());
                  if (val == null || val <= 0) return 'Enter a valid positive amount';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _label(context, 'Initial Savings (optional)'),
              const SizedBox(height: 4),
              Text(
                'Available in wallet: EGP ${walletSavings.toStringAsFixed(0)}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _initialController,
                enabled: walletSavings > 0,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixText: 'EGP  ',
                  hintText: '0.00',
                  helperText: walletSavings > 0
                      ? 'Max EGP ${walletSavings.toStringAsFixed(0)}'
                      : 'No savings available in wallet',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final val = double.tryParse(v.trim());
                  if (val == null || val < 0) return 'Enter a valid amount';
                  if (val > walletSavings) {
                    return 'Exceeds wallet balance (EGP ${walletSavings.toStringAsFixed(0)})';
                  }
                  final target = double.tryParse(_targetController.text.trim());
                  if (target != null && val > target) {
                    return 'Cannot exceed target amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _label(context, 'Target Deadline'),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _pickDate(context),
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.calendar_today_outlined)),
                  child: Text(DateFormat('MMM dd, yyyy').format(_deadline)),
                ),
              ),
              const SizedBox(height: 12),
              _DeadlineSummary(
                target: double.tryParse(_targetController.text) ?? 0,
                deadline: _deadline,
              ),
              const SizedBox(height: 32),

              Consumer<GoalProvider>(
                builder: (context, provider, _) => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: provider.isLoading ? null : _submit,
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Create Goal',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    return Text(text,
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(fontWeight: FontWeight.w600));
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<GoalProvider>();
    final initialText = _initialController.text.trim();
    final initialAmount =
        initialText.isEmpty ? null : double.tryParse(initialText);

    final success = await provider.createGoal(
      name: _nameController.text.trim(),
      targetAmount: double.parse(_targetController.text.trim()),
      deadline: _deadline,
      currentAmount: (initialAmount != null && initialAmount > 0)
          ? initialAmount
          : null,
    );

    if (!mounted) return;

    if (success) {
      // Refresh wallet if initial amount was deducted
      if (initialAmount != null && initialAmount > 0) {
        context.read<WalletProvider>().loadWallet();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal created successfully!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to create goal')),
      );
    }
  }
}

class _DeadlineSummary extends StatelessWidget {
  final double target;
  final DateTime deadline;

  const _DeadlineSummary({required this.target, required this.deadline});

  @override
  Widget build(BuildContext context) {
    final days = deadline.difference(DateTime.now()).inDays;
    if (days <= 0 || target <= 0) return const SizedBox.shrink();
    final months = days / 30;
    final monthly = target / months;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Days remaining',
                  style: Theme.of(context).textTheme.bodyMedium),
              Text('$days days',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Monthly savings needed',
                  style: Theme.of(context).textTheme.bodyMedium),
              Text(
                'EGP ${monthly.toStringAsFixed(0)}/month',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
