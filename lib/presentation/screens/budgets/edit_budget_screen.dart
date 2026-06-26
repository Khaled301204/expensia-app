import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/config/theme.dart';
import '../../../data/models/budget.dart';
import '../../providers/budget_provider.dart';

class EditBudgetScreen extends StatefulWidget {
  final Budget budget;
  const EditBudgetScreen({super.key, required this.budget});
  @override
  State<EditBudgetScreen> createState() => _EditBudgetScreenState();
}

class _EditBudgetScreenState extends State<EditBudgetScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _limitCtrl   = TextEditingController();

  DateTime _endDate       = DateTime.now();
  double   _alertThreshold = 0.80;

  @override
  void initState() {
    super.initState();
    final b = widget.budget;
    _limitCtrl.text  = b.limitAmount.toStringAsFixed(2);
    _endDate         = b.endDate;
    _alertThreshold  = b.alertThreshold;
  }

  @override
  void dispose() {
    _limitCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<BudgetProvider>();
    final ok = await provider.updateBudget(
      id:             widget.budget.id,
      limitAmount:    double.parse(_limitCtrl.text.trim()),
      endDate:        _endDate,
      alertThreshold: _alertThreshold,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget updated!')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to update budget')));
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
        title: Text('Edit Budget', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(key: _formKey, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Category badge (read-only)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.category_outlined, color: AppTheme.warningColor, size: 16),
                const SizedBox(width: 8),
                Text(widget.budget.categoryName,
                    style: GoogleFonts.inter(
                        color: AppTheme.warningColor, fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('Category cannot be changed',
                    style: GoogleFonts.inter(color: AppTheme.darkTextMuted, fontSize: 11)),
              ]),
            ),
            const SizedBox(height: 24),

            _Label('Spending Limit'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _limitCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.inter(
                  color: AppTheme.darkTextPri, fontSize: 28, fontWeight: FontWeight.w800),
              decoration: const InputDecoration(prefixText: 'EGP  ', hintText: '0.00'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter a limit';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'Enter a valid positive amount';
                return null;
              },
            ),
            const SizedBox(height: 20),

            _Label('End Date'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickEndDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.event_outlined, size: 18)),
                child: Text(DateFormat('MMM dd, yyyy').format(_endDate),
                    style: GoogleFonts.inter(color: AppTheme.darkTextPri, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 24),

            _Label('Alert Threshold — ${(_alertThreshold * 100).toStringAsFixed(0)}%'),
            const SizedBox(height: 4),
            Text('Notify when this % of budget is used',
                style: GoogleFonts.inter(color: AppTheme.darkTextMuted, fontSize: 12)),
            Slider(
              value: _alertThreshold,
              min: 0.5,
              max: 1.0,
              divisions: 10,
              activeColor: AppTheme.warningColor,
              label: '${(_alertThreshold * 100).toStringAsFixed(0)}%',
              onChanged: (v) => setState(() => _alertThreshold = v),
            ),
            const SizedBox(height: 36),

            Consumer<BudgetProvider>(builder: (_, provider, __) =>
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: provider.isLoading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
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

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _endDate = picked);
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
