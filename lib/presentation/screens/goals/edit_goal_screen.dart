import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/config/theme.dart';
import '../../../data/models/goal.dart';
import '../../providers/goal_provider.dart';

class EditGoalScreen extends StatefulWidget {
  final Goal goal;
  const EditGoalScreen({super.key, required this.goal});
  @override
  State<EditGoalScreen> createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends State<EditGoalScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _targetCtrl   = TextEditingController();

  DateTime _deadline = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _nameCtrl.text   = g.name;
    _targetCtrl.text = g.targetAmount.toStringAsFixed(2);
    _deadline        = g.deadline;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<GoalProvider>();
    final ok = await provider.updateGoal(
      id:           widget.goal.id,
      name:         _nameCtrl.text.trim(),
      targetAmount: double.parse(_targetCtrl.text.trim()),
      deadline:     _deadline,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal updated!')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to update goal')));
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
        title: Text('Edit Goal', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(key: _formKey, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _Label('Goal Name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              style: GoogleFonts.inter(color: AppTheme.darkTextPri, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'e.g. Emergency Fund, New Laptop',
                prefixIcon: Icon(Icons.flag_outlined, size: 18),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 20),

            _Label('Target Amount'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _targetCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.inter(
                  color: AppTheme.darkTextPri, fontSize: 28, fontWeight: FontWeight.w800),
              decoration: const InputDecoration(prefixText: 'EGP  ', hintText: '0.00'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter a target amount';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'Enter a valid positive amount';
                return null;
              },
            ),
            const SizedBox(height: 20),

            _Label('Deadline'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDeadline,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.event_outlined, size: 18)),
                child: Text(DateFormat('MMM dd, yyyy').format(_deadline),
                    style: GoogleFonts.inter(color: AppTheme.darkTextPri, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 12),

            // Progress info (read-only)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.darkBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Stat('Saved', 'EGP ${widget.goal.currentAmount.toStringAsFixed(0)}',
                      AppTheme.primaryColor),
                  _Stat('Progress',
                      '${(widget.goal.currentAmount / widget.goal.targetAmount * 100).clamp(0, 100).toStringAsFixed(0)}%',
                      AppTheme.secondaryColor),
                  _Stat('Remaining',
                      'EGP ${widget.goal.remaining.abs().toStringAsFixed(0)}',
                      AppTheme.darkTextSec),
                ],
              ),
            ),
            const SizedBox(height: 36),

            Consumer<GoalProvider>(builder: (_, provider, __) =>
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

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _deadline = picked);
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

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: GoogleFonts.inter(color: AppTheme.darkTextMuted, fontSize: 11)),
    const SizedBox(height: 4),
    Text(value, style: GoogleFonts.inter(
        color: color, fontSize: 14, fontWeight: FontWeight.w700)),
  ]);
}
