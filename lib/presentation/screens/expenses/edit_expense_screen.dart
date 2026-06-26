import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/config/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/category.dart';
import '../../../data/repositories/category_repository.dart';
import '../../providers/expense_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/budget_provider.dart';

class EditExpenseScreen extends StatefulWidget {
  final Expense expense;
  const EditExpenseScreen({super.key, required this.expense});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _amountCtrl      = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _merchantCtrl    = TextEditingController();

  String   _selectedPayment = AppConstants.paymentMethods.first;
  DateTime _selectedDate    = DateTime.now();
  int?     _selectedCategoryId;

  List<Category> _categories = [];
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _amountCtrl.text      = e.amount.toStringAsFixed(2);
    _descriptionCtrl.text = e.description ?? '';
    _merchantCtrl.text    = e.merchant ?? '';
    _selectedDate         = e.date;
    _selectedPayment      = _normalizePayment(e.paymentMethod);
    _selectedCategoryId   = e.categoryId;
    _loadCategories();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    _merchantCtrl.dispose();
    super.dispose();
  }

  String _normalizePayment(String? raw) {
    if (raw == null) return AppConstants.paymentMethods.first;
    const map = {
      'CASH': 'Cash',
      'CREDIT_CARD': 'Credit Card',
      'DEBIT_CARD': 'Debit Card',
      'BANK_TRANSFER': 'Bank Transfer',
      'MOBILE_PAYMENT': 'Mobile Payment',
    };
    final mapped = map[raw.toUpperCase()] ?? raw;
    return AppConstants.paymentMethods.contains(mapped)
        ? mapped
        : AppConstants.paymentMethods.first;
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await CategoryRepository().getCategories();
      if (mounted) setState(() { _categories = cats; _loadingCategories = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ExpenseProvider>();
    final ok = await provider.updateExpense(
      id:            widget.expense.id,
      amount:        double.parse(_amountCtrl.text.trim()),
      categoryId:    _selectedCategoryId,
      date:          _selectedDate,
      description:   _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
      merchant:      _merchantCtrl.text.trim().isEmpty ? null : _merchantCtrl.text.trim(),
      paymentMethod: _selectedPayment,
    );
    if (!mounted) return;
    if (ok) {
      context.read<DashboardProvider>().loadDashboard();
      context.read<BudgetProvider>().loadBudgets();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense updated!')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to update expense')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        foregroundColor: AppTheme.darkTextPri,
        surfaceTintColor: Colors.transparent,
        title: Text('Edit Expense', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: _loadingCategories
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(key: _formKey, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  _Label('Amount'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.inter(
                        color: AppTheme.darkTextPri, fontSize: 28, fontWeight: FontWeight.w800),
                    decoration: const InputDecoration(prefixText: 'EGP  ', hintText: '0.00'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter an amount';
                      final n = double.tryParse(v.trim());
                      if (n == null || n <= 0) return 'Enter a valid positive amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  _Label('Date'),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.calendar_today_outlined, size: 18)),
                      child: Text(DateFormat('MMM dd, yyyy').format(_selectedDate),
                          style: GoogleFonts.inter(
                              color: AppTheme.darkTextPri, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _Label('Category'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedCategoryId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.category_outlined, size: 18)),
                    hint: Text('Select category',
                        style: GoogleFonts.inter(color: AppTheme.darkTextMuted, fontSize: 14)),
                    items: _categories.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedCategoryId = v),
                  ),
                  const SizedBox(height: 20),

                  _Label('Merchant (optional)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _merchantCtrl,
                    style: GoogleFonts.inter(color: AppTheme.darkTextPri, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Carrefour, Costa Coffee',
                      prefixIcon: Icon(Icons.store_outlined, size: 18),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _Label('Description (optional)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionCtrl,
                    maxLines: 2,
                    style: GoogleFonts.inter(color: AppTheme.darkTextPri, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Add a note...',
                      prefixIcon: Icon(Icons.notes, size: 18),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _Label('Payment Method'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPayment,
                    isExpanded: true,
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.payment_outlined, size: 18)),
                    items: AppConstants.paymentMethods.map((m) =>
                        DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setState(() => _selectedPayment = v!),
                  ),
                  const SizedBox(height: 36),

                  Consumer<ExpenseProvider>(builder: (_, provider, __) =>
                    SizedBox(width: double.infinity, height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: provider.isLoading ? null : const LinearGradient(
                            colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          color: provider.isLoading ? AppTheme.darkElevated : null,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: provider.isLoading ? [] : [AppTheme.blueGlow],
                        ),
                        child: ElevatedButton(
                          onPressed: provider.isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: provider.isLoading
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : Text('Save Changes', style: GoogleFonts.inter(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                ],
              )),
            ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: GoogleFonts.inter(
      color: AppTheme.darkTextSec, fontSize: 12,
      fontWeight: FontWeight.w500, letterSpacing: 0.2));
}
