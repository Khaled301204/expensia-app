import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/config/theme.dart';
import '../../../data/models/category.dart';
import '../../../data/models/voice_preview.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/services/voice_service.dart';
import '../../providers/expense_provider.dart';

enum _VoiceStep { idle, recording, processing, preview, confirming, done }

class VoiceExpenseScreen extends StatefulWidget {
  const VoiceExpenseScreen({super.key});

  @override
  State<VoiceExpenseScreen> createState() => _VoiceExpenseScreenState();
}

class _VoiceExpenseScreenState extends State<VoiceExpenseScreen>
    with SingleTickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();
  _VoiceStep _step = _VoiceStep.idle;
  String? _errorMessage;

  // Recording timer
  Timer? _timer;
  int _seconds = 0;

  // Preview state
  VoicePreview? _preview;
  List<Category> _categories = [];

  // Edit controllers (populated from preview)
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _descriptionController = TextEditingController();
  Category? _editCategory;
  DateTime _editDate = DateTime.now();

  // Pulse animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 1.0, end: 1.25).animate(_pulseController);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    _categories = await CategoryRepository().getCategories();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _voiceService.dispose();
    _pulseController.dispose();
    _amountController.dispose();
    _merchantController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // â”€â”€ Recording â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _startRecording() async {
    final started = await _voiceService.startRecording();
    if (!started) {
      setState(() => _errorMessage =
          'Microphone permission denied. Please enable it in settings.');
      return;
    }
    setState(() {
      _step = _VoiceStep.recording;
      _seconds = 0;
      _errorMessage = null;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    setState(() => _step = _VoiceStep.processing);

    final path = await _voiceService.stopRecording();
    if (path == null) {
      setState(() {
        _step = _VoiceStep.idle;
        _errorMessage = 'Recording failed. Please try again.';
      });
      return;
    }

    final provider = context.read<ExpenseProvider>();
    final preview = await provider.previewVoiceExpense(path);

    if (preview == null || !mounted) {
      setState(() {
        _step = _VoiceStep.idle;
        _errorMessage = provider.error ?? 'Could not analyse the audio.';
      });
      return;
    }

    _populatePreviewFields(preview);
    setState(() {
      _preview = preview;
      _step = _VoiceStep.preview;
    });
  }

  void _populatePreviewFields(VoicePreview p) {
    _amountController.text = p.amount.toStringAsFixed(2);
    _merchantController.text = p.merchant ?? '';
    _descriptionController.text = p.description ?? '';
    _editDate = p.date;
    if (p.categoryId != null) {
      _editCategory = _categories
          .where((c) => c.id == p.categoryId)
          .firstOrNull;
    }
    _editCategory ??= _categories.isNotEmpty ? _categories.first : null;
  }

  // â”€â”€ Confirm â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _confirmExpense() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    setState(() => _step = _VoiceStep.confirming);

    final corrected = VoicePreview(
      amount: amount,
      merchant: _merchantController.text.trim().isEmpty
          ? null
          : _merchantController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      date: _editDate,
      categoryId: _editCategory?.id,
      categoryName: _editCategory?.name,
    );

    final provider = context.read<ExpenseProvider>();
    final success = await provider.confirmVoiceExpense(corrected);

    if (!mounted) return;
    if (success) {
      setState(() => _step = _VoiceStep.done);
    } else {
      setState(() {
        _step = _VoiceStep.preview;
        _errorMessage = provider.error ?? 'Failed to create expense.';
      });
    }
  }

  // â”€â”€ UI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Expense'),
        actions: [
          if (_step == _VoiceStep.preview)
            TextButton(
              onPressed: () => setState(() => _step = _VoiceStep.idle),
              child: const Text('Retake'),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case _VoiceStep.idle:
        return _IdleView(
          onRecord: _startRecording,
          error: _errorMessage,
        );
      case _VoiceStep.recording:
        return _RecordingView(
          seconds: _seconds,
          onStop: _stopRecording,
          pulseAnimation: _pulseAnimation,
        );
      case _VoiceStep.processing:
        return const _ProcessingView();
      case _VoiceStep.preview:
        return _PreviewForm(
          categories: _categories,
          amountController: _amountController,
          merchantController: _merchantController,
          descriptionController: _descriptionController,
          selectedCategory: _editCategory,
          selectedDate: _editDate,
          confidence: _preview?.categoryConfidence,
          onCategoryChanged: (c) => setState(() => _editCategory = c),
          onDateChanged: (d) => setState(() => _editDate = d),
          onConfirm: _confirmExpense,
          error: _errorMessage,
        );
      case _VoiceStep.confirming:
        return const _ProcessingView(label: 'Creating expense...');
      case _VoiceStep.done:
        return _DoneView(onFinish: () => Navigator.pop(context));
    }
  }
}

// â”€â”€ Idle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _IdleView extends StatelessWidget {
  final VoidCallback onRecord;
  final String? error;
  const _IdleView({required this.onRecord, this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.mic_outlined,
                  size: 56, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 32),
            Text('Voice Expense',
                style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 12),
            Text(
              'Tap the microphone and describe your expense.\nOur AI will extract the details automatically.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(error!,
                    style: const TextStyle(color: AppTheme.errorColor),
                    textAlign: TextAlign.center),
              ),
            ],
            const SizedBox(height: 40),
            GestureDetector(
              onTap: onRecord,
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor,
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.primaryColor,
                        blurRadius: 20,
                        spreadRadius: 4,
                        offset: Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 36),
              ),
            ),
            const SizedBox(height: 16),
            Text('Tap to record',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Recording â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _RecordingView extends StatelessWidget {
  final int seconds;
  final VoidCallback onStop;
  final Animation<double> pulseAnimation;

  const _RecordingView({
    required this.seconds,
    required this.onStop,
    required this.pulseAnimation,
  });

  String get _elapsed {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: pulseAnimation,
            builder: (_, child) => Transform.scale(
              scale: pulseAnimation.value,
              child: child,
            ),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.errorColor.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.mic, size: 56, color: AppTheme.errorColor),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Recording...',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: AppTheme.errorColor),
          ),
          const SizedBox(height: 8),
          Text(_elapsed,
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(fontFamily: 'monospace')),
          const SizedBox(height: 8),
          Text('Speak naturally â€” say the amount, what you bought, where.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: onStop,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.errorColor,
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.errorColor.withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 2),
                ],
              ),
              child: const Icon(Icons.stop, color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(height: 16),
          Text('Tap to stop', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

// â”€â”€ Processing â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ProcessingView extends StatelessWidget {
  final String label;
  const _ProcessingView({this.label = 'Analysing audio...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(label, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Our AI is processing your voice recording',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

// â”€â”€ Preview Form â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PreviewForm extends StatelessWidget {
  final List<Category> categories;
  final TextEditingController amountController;
  final TextEditingController merchantController;
  final TextEditingController descriptionController;
  final Category? selectedCategory;
  final DateTime selectedDate;
  final double? confidence;
  final ValueChanged<Category?> onCategoryChanged;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onConfirm;
  final String? error;

  const _PreviewForm({
    required this.categories,
    required this.amountController,
    required this.merchantController,
    required this.descriptionController,
    required this.selectedCategory,
    required this.selectedDate,
    required this.onCategoryChanged,
    required this.onDateChanged,
    required this.onConfirm,
    this.confidence,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AiBadge(confidence: confidence),
          const SizedBox(height: 20),
          if (error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(error!,
                  style: const TextStyle(color: AppTheme.errorColor)),
            ),
          ],
          Text('Review & Edit',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('AI extracted these details. Edit any field before confirming.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          _fieldLabel(context, 'Amount (EGP)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: amountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style:
                const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              prefixText: 'EGP  ',
              prefixStyle: TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(height: 20),
          _fieldLabel(context, 'Category'),
          const SizedBox(height: 8),
          DropdownButtonFormField<Category>(
            value: selectedCategory,
            isExpanded: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: categories
                .map((c) =>
                    DropdownMenuItem(value: c, child: Text(c.name)))
                .toList(),
            onChanged: onCategoryChanged,
          ),
          const SizedBox(height: 20),
          _fieldLabel(context, 'Merchant'),
          const SizedBox(height: 8),
          TextFormField(
            controller: merchantController,
            decoration: const InputDecoration(
              hintText: 'Where did you spend?',
              prefixIcon: Icon(Icons.store_outlined),
            ),
          ),
          const SizedBox(height: 20),
          _fieldLabel(context, 'Description'),
          const SizedBox(height: 8),
          TextFormField(
            controller: descriptionController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'What was it for?',
              prefixIcon: Icon(Icons.notes),
            ),
          ),
          const SizedBox(height: 20),
          _fieldLabel(context, 'Date'),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) onDateChanged(picked);
            },
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today_outlined)),
              child:
                  Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onConfirm,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Confirm & Save Expense',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _fieldLabel(BuildContext context, String text) {
    return Text(text,
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(fontWeight: FontWeight.w600));
  }
}

class _AiBadge extends StatelessWidget {
  final double? confidence;
  const _AiBadge({this.confidence});

  @override
  Widget build(BuildContext context) {
    final pct = confidence != null
        ? '${(confidence! * 100).toStringAsFixed(0)}% confidence'
        : 'AI extracted';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology_outlined,
              color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text('AI extracted details â€” $pct',
                style: const TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Done â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _DoneView extends StatelessWidget {
  final VoidCallback onFinish;
  const _DoneView({required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.successColor.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.check_circle,
                  size: 56, color: AppTheme.successColor),
            ),
            const SizedBox(height: 24),
            Text('Expense Saved!',
                style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 12),
            Text('Your voice expense was successfully created.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onFinish,
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
