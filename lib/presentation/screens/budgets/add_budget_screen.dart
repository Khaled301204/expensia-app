import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/models/category.dart';
import '../../../data/repositories/category_repository.dart';
import '../../providers/budget_provider.dart';

class AddBudgetScreen extends StatefulWidget {
  const AddBudgetScreen({super.key});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _limitController = TextEditingController();

  Category? _selectedCategory;
  List<Category> _categories = [];
  bool _loadingCategories = true;

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  double _alertThreshold = 0.80;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await CategoryRepository().getCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
        _selectedCategory = cats.isNotEmpty ? cats.first : null;
        _loadingCategories = false;
      });
    }
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Budget')),
      body: _loadingCategories
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(context, 'Category'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Category>(
                      value: _selectedCategory,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.category_outlined)),
                      items: _categories
                          .map((c) => DropdownMenuItem(
                              value: c, child: Text(c.name)))
                          .toList(),
                      onChanged: (c) => setState(() => _selectedCategory = c),
                      validator: (v) =>
                          v == null ? 'Select a category' : null,
                    ),
                    const SizedBox(height: 20),
                    _label(context, 'Spending Limit (EGP)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _limitController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        prefixText: 'EGP  ',
                        hintText: '0.00',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter a limit amount';
                        }
                        final val = double.tryParse(v.trim());
                        if (val == null || val <= 0) {
                          return 'Enter a valid positive amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label(context, 'Start Date'),
                              const SizedBox(height: 8),
                              _DatePickerField(
                                date: _startDate,
                                onTap: () => _pickDate(context, isStart: true),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label(context, 'End Date'),
                              const SizedBox(height: 8),
                              _DatePickerField(
                                date: _endDate,
                                onTap: () => _pickDate(context, isStart: false),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _label(context, 'Alert Threshold'),
                    const SizedBox(height: 4),
                    Text(
                      'Notify when ${(_alertThreshold * 100).toStringAsFixed(0)}% of budget is used',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Slider(
                      value: _alertThreshold,
                      min: 0.5,
                      max: 0.95,
                      divisions: 9,
                      label:
                          '${(_alertThreshold * 100).toStringAsFixed(0)}%',
                      onChanged: (v) =>
                          setState(() => _alertThreshold = v),
                    ),
                    const SizedBox(height: 32),
                    Consumer<BudgetProvider>(
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
                              : const Text('Create Budget',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
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

  Future<void> _pickDate(BuildContext context, {required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final firstDate = isStart ? DateTime(2020) : _startDate;
    final lastDate = DateTime(2030);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(picked)) {
            _endDate = picked.add(const Duration(days: 30));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) return;

    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date')),
      );
      return;
    }

    final provider = context.read<BudgetProvider>();
    final success = await provider.createBudget(
      categoryId: _selectedCategory!.id,
      limitAmount: double.parse(_limitController.text.trim()),
      startDate: _startDate,
      endDate: _endDate,
      alertThreshold: _alertThreshold,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget created successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to create budget')),
        );
      }
    }
  }
}

class _DatePickerField extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerField({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
          isDense: true,
        ),
        child: Text(DateFormat('MMM dd, yyyy').format(date),
            style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}
