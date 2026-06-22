import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/config/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/category.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/services/api_service.dart';
import '../../../core/config/app_config.dart';
import '../../providers/expense_provider.dart';
import '../../providers/dashboard_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});
  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey              = GlobalKey<FormState>();
  final _amountCtrl           = TextEditingController();
  final _descriptionCtrl      = TextEditingController();
  final _merchantCtrl         = TextEditingController();
  final _parseTextCtrl        = TextEditingController();

  Category? _selectedCategory;
  String    _selectedPayment  = AppConstants.paymentMethods.first;
  DateTime  _selectedDate     = DateTime.now();
  List<Category> _categories  = [];
  bool _loadingCategories     = true;
  bool _parsing               = false;
  bool _showParseBar          = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await CategoryRepository().getCategories();
      if (mounted) setState(() {
        _categories = cats;
        _selectedCategory = cats.isNotEmpty ? cats.first : null;
        _loadingCategories = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    _merchantCtrl.dispose();
    _parseTextCtrl.dispose();
    super.dispose();
  }

  // ── AI parse text → pre-fill form ─────────────────────────────────────────

  Future<void> _parseText() async {
    final text = _parseTextCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _parsing = true);
    try {
      final api = ApiService();
      final response = await api.post(
        AppConfig.parseTextEndpoint,
        data: {'text': text},
      );
      final body = response.data;
      final data = (body is Map && body['success'] == true) ? body['data'] : body;
      if (data is Map) {
        setState(() {
          if (data['amount'] != null) {
            _amountCtrl.text = (data['amount'] as num).toStringAsFixed(2);
          }
          if (data['description'] != null) {
            _descriptionCtrl.text = data['description'].toString();
          }
          if (data['merchant'] != null) {
            _merchantCtrl.text = data['merchant'].toString();
          }
          if (data['categoryId'] != null || data['categoryName'] != null) {
            final catId   = data['categoryId'] as int?;
            final catName = (data['categoryName'] ?? data['category'])?.toString();
            _selectedCategory = _categories.firstWhere(
              (c) => c.id == catId || c.name == catName,
              orElse: () => _selectedCategory ?? _categories.first,
            );
          }
          _showParseBar = false;
          _parseTextCtrl.clear();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Fields pre-filled from your text')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('AI parse failed: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _parsing = false);
    }
  }

  // ── Manual submit ──────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')));
      return;
    }
    final provider = context.read<ExpenseProvider>();
    final ok = await provider.createExpense(
      amount:        double.parse(_amountCtrl.text.trim()),
      categoryId:    _selectedCategory!.id,
      date:          _selectedDate,
      description:   _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
      merchant:      _merchantCtrl.text.trim().isEmpty ? null : _merchantCtrl.text.trim(),
      paymentMethod: _selectedPayment,
    );
    if (!mounted) return;
    if (ok) {
      context.read<DashboardProvider>().loadDashboard();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense added!')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to add expense')));
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
        title: Text('Add Expense', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'AI parse from text',
            icon: Icon(Icons.auto_awesome,
                color: _showParseBar ? AppTheme.primaryColor : AppTheme.darkTextSec),
            onPressed: () => setState(() => _showParseBar = !_showParseBar),
          ),
        ],
      ),
      body: _loadingCategories
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : Column(children: [

              // ── AI parse bar (collapsible) ─────────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                child: _showParseBar
                  ? Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      color: AppTheme.darkElevated,
                      child: Row(children: [
                        Expanded(child: TextField(
                          controller: _parseTextCtrl,
                          style: GoogleFonts.inter(color: AppTheme.darkTextPri, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'e.g. "spent 150 on lunch at Cairo Kitchen"',
                            hintStyle: GoogleFonts.inter(
                                color: AppTheme.darkTextMuted, fontSize: 13),
                            prefixIcon: const Icon(Icons.auto_awesome,
                                color: AppTheme.primaryColor, size: 18),
                            isDense: true,
                          ),
                          textInputAction: TextInputAction.go,
                          onSubmitted: (_) => _parseText(),
                        )),
                        const SizedBox(width: 8),
                        _parsing
                          ? const SizedBox(width: 24, height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2.5,
                                  color: AppTheme.primaryColor))
                          : TextButton(
                              onPressed: _parseText,
                              child: Text('Parse', style: GoogleFonts.inter(
                                  color: AppTheme.primaryColor, fontWeight: FontWeight.w600))),
                      ]),
                    )
                  : const SizedBox.shrink(),
              ),

              // ── Form ──────────────────────────────────────────────────────
              Expanded(child: SingleChildScrollView(
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

                    _Label('Category'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Category>(
                      value: _selectedCategory,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.category_outlined, size: 18)),
                      items: _categories.map((c) =>
                          DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                      onChanged: (c) => setState(() => _selectedCategory = c),
                      validator: (v) => v == null ? 'Select a category' : null,
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
                      value: _selectedPayment,
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
                              : Text('Add Expense', style: GoogleFonts.inter(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ),
                  ],
                )),
              )),
            ]),
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
