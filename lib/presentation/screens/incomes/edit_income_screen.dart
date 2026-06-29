import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/config/theme.dart';
import '../../../data/models/income.dart';
import '../../providers/income_provider.dart';
import '../../providers/dashboard_provider.dart';

class EditIncomeScreen extends StatefulWidget {
  final Income income;
  const EditIncomeScreen({super.key, required this.income});
  @override
  State<EditIncomeScreen> createState() => _EditIncomeScreenState();
}

class _EditIncomeScreenState extends State<EditIncomeScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();

  DateTime _selectedDate    = DateTime.now();
  bool     _isRecurring     = false;
  String?  _frequency;
  bool     _recurringActive = true;

  static const _frequencies = ['DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY'];
  static const _freqLabels  = {'DAILY': 'Daily', 'WEEKLY': 'Weekly', 'MONTHLY': 'Monthly', 'YEARLY': 'Yearly'};

  @override
  void initState() {
    super.initState();
    final i = widget.income;
    _amountCtrl.text = i.amount.toStringAsFixed(2);
    _sourceCtrl.text = i.source;
    _selectedDate    = i.date;
    _isRecurring      = i.isRecurring;
    _frequency        = i.frequency ?? 'MONTHLY';
    _recurringActive  = i.recurringActive;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _sourceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<IncomeProvider>();
    final ok = await provider.updateIncome(
      id:          widget.income.id,
      amount:      double.parse(_amountCtrl.text.trim()),
      date:        _selectedDate,
      source:      _sourceCtrl.text.trim(),
      frequency:       _isRecurring ? _frequency : null,
      isRecurring:     _isRecurring,
      recurringActive: _isRecurring ? _recurringActive : null,
    );
    if (!mounted) return;
    if (ok) {
      context.read<DashboardProvider>().loadDashboard();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Income updated!')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to update income')));
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
        title: Text('Edit Income', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
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

            _Label('Source'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _sourceCtrl,
              style: GoogleFonts.inter(color: AppTheme.darkTextPri, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'e.g. Salary, Freelance, Bonus',
                prefixIcon: Icon(Icons.work_outline, size: 18),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Source is required' : null,
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
                    style: GoogleFonts.inter(color: AppTheme.darkTextPri, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 20),

            Row(children: [
              Switch(
                value: _isRecurring,
                activeThumbColor: AppTheme.secondaryColor,
                onChanged: (v) => setState(() {
                  _isRecurring = v;
                  if (v) _frequency ??= 'MONTHLY';
                }),
              ),
              const SizedBox(width: 8),
              Text('Recurring Income',
                  style: GoogleFonts.inter(color: AppTheme.darkTextPri, fontSize: 14)),
            ]),

            if (_isRecurring) ...[
              const SizedBox(height: 12),
              _Label('Frequency'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _frequency,
                isExpanded: true,
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.repeat, size: 18)),
                items: _frequencies.map((f) =>
                    DropdownMenuItem(value: f, child: Text(_freqLabels[f]!))).toList(),
                onChanged: (v) => setState(() => _frequency = v),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.darkElevated),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  secondary: Icon(
                    _recurringActive ? Icons.repeat : Icons.pause_circle_outline,
                    color: _recurringActive ? AppTheme.secondaryColor : AppTheme.darkTextMuted,
                    size: 20,
                  ),
                  title: Text(
                    _recurringActive ? 'Active' : 'Paused',
                    style: GoogleFonts.inter(
                        color: AppTheme.darkTextPri,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    _recurringActive
                        ? 'Income recurs automatically'
                        : 'No new copies will be created',
                    style: GoogleFonts.inter(
                        color: AppTheme.darkTextMuted, fontSize: 12),
                  ),
                  value: _recurringActive,
                  activeThumbColor: AppTheme.secondaryColor,
                  activeTrackColor: AppTheme.secondaryColor.withValues(alpha: 0.4),
                  onChanged: (v) => setState(() => _recurringActive = v),
                ),
              ),
            ],
            const SizedBox(height: 36),

            Consumer<IncomeProvider>(builder: (_, provider, __) =>
              SizedBox(width: double.infinity, height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: provider.isLoading ? null : const LinearGradient(
                      colors: [Color(0xFF059669), AppTheme.secondaryColor],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    color: provider.isLoading ? AppTheme.darkElevated : null,
                    borderRadius: BorderRadius.circular(12),
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
