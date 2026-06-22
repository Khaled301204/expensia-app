import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/config/theme.dart';
import '../../providers/income_provider.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});
  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _amountCtrl   = TextEditingController();
  final _sourceCtrl   = TextEditingController();

  DateTime _date         = DateTime.now();
  String?  _frequency    = 'MONTHLY';
  bool     _isRecurring  = false;

  static const _sources = [
    'Salary', 'Freelance', 'Business', 'Investment',
    'Rental', 'Bonus', 'Pension', 'Other',
  ];

  static const _frequencies = [
    ('ONE_TIME', 'One-time'),
    ('DAILY',    'Daily'),
    ('WEEKLY',   'Weekly'),
    ('MONTHLY',  'Monthly'),
    ('YEARLY',   'Yearly'),
  ];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _sourceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Text('Add Income', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.darkBg,
        foregroundColor: AppTheme.darkTextPri,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Amount
            _Label('Amount'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.inter(
                color: AppTheme.darkTextPri, fontSize: 28, fontWeight: FontWeight.w800,
              ),
              decoration: const InputDecoration(
                prefixText: 'EGP  ',
                hintText: '0.00',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter an amount';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'Enter a valid positive amount';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Source
            _Label('Source'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _sources.contains(_sourceCtrl.text) ? _sourceCtrl.text : null,
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.work_outline, size: 18),
              ),
              items: _sources.map((s) =>
                DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _sourceCtrl.text = v);
              },
              validator: (_) => _sourceCtrl.text.isEmpty ? 'Select a source' : null,
            ),
            const SizedBox(height: 24),

            // Date
            _Label('Date'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                ),
                child: Text(
                  DateFormat('MMM dd, yyyy').format(_date),
                  style: GoogleFonts.inter(color: AppTheme.darkTextPri, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Recurring toggle
            Row(children: [
              Text('Recurring income', style: GoogleFonts.inter(
                color: AppTheme.darkTextPri, fontSize: 14, fontWeight: FontWeight.w500,
              )),
              const Spacer(),
              Switch(
                value: _isRecurring,
                activeColor: AppTheme.secondaryColor,
                onChanged: (v) => setState(() {
                  _isRecurring = v;
                  if (!v) _frequency = null;
                  else _frequency ??= 'MONTHLY';
                }),
              ),
            ]),

            // Frequency (only when recurring)
            if (_isRecurring) ...[
              const SizedBox(height: 16),
              _Label('Frequency'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _frequency,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.repeat, size: 18),
                ),
                items: _frequencies.map((f) =>
                  DropdownMenuItem(value: f.$1, child: Text(f.$2))).toList(),
                onChanged: (v) => setState(() => _frequency = v),
              ),
            ],

            const SizedBox(height: 40),

            // Submit button
            Consumer<IncomeProvider>(builder: (_, provider, __) =>
              SizedBox(width: double.infinity, height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: provider.isLoading ? null : const LinearGradient(
                      colors: [AppTheme.secondaryColor, Color(0xFF059669)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    color: provider.isLoading ? AppTheme.darkElevated : null,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: provider.isLoading ? [] : [BoxShadow(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                      blurRadius: 20, offset: const Offset(0, 6),
                    )],
                  ),
                  child: ElevatedButton(
                    onPressed: provider.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: provider.isLoading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text('Add Income', style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sourceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a source')));
      return;
    }

    final provider = context.read<IncomeProvider>();
    final ok = await provider.createIncome(
      amount: double.parse(_amountCtrl.text.trim()),
      date: _date,
      source: _sourceCtrl.text,
      frequency: _isRecurring ? _frequency : null,
      isRecurring: _isRecurring,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Income added successfully!')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to add income')));
    }
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: GoogleFonts.inter(
      color: AppTheme.darkTextSec, fontSize: 12,
      fontWeight: FontWeight.w500, letterSpacing: 0.2,
    ));
}
