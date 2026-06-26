import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/config/theme.dart';
import '../../../core/utils/validators.dart';
import '../../../routes/app_router.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart' show AuthFieldLabel, GradientButton;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _confCtrl   = TextEditingController();
  bool _obscure = true, _obscureC = true;
  String _riskPreference = 'MEDIUM';

  @override
  void dispose() {
    for (final c in [_nameCtrl, _emailCtrl, _phoneCtrl, _passCtrl, _confCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      riskPreference: _riskPreference,
    );
    if (!mounted) return;
    if (ok) { Navigator.pushReplacementNamed(context, AppRouter.home); }
    else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error ?? 'Registration failed'),
        backgroundColor: AppTheme.errorColor,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Stack(children: [
        Positioned(top: -100, right: -100,
          child: _Glow(color: AppTheme.accentPurple, size: 300, opacity: 0.15)),
        Positioned(bottom: -60, left: -60,
          child: _Glow(color: AppTheme.primaryColor, size: 220, opacity: 0.12)),
        SafeArea(child: Column(children: [
          // Back button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.darkElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: AppTheme.darkTextPri, size: 15),
                ),
              ),
            ]),
          ),

          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(key: _formKey, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text('Create account', style: GoogleFonts.inter(
                  color: AppTheme.darkTextPri, fontSize: 30,
                  fontWeight: FontWeight.w800, letterSpacing: -0.8, height: 1.1,
                )),
                const SizedBox(height: 6),
                Text('Start your financial journey today', style: GoogleFonts.inter(
                  color: AppTheme.darkTextSec, fontSize: 14,
                )),
                const SizedBox(height: 32),

                AuthFieldLabel('Full name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  validator: Validators.validateName,
                  style: GoogleFonts.inter(color: AppTheme.darkTextPri, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'John Doe',
                    prefixIcon: Icon(Icons.person_outline, size: 18),
                  ),
                ),
                const SizedBox(height: 16),

                AuthFieldLabel('Email address'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  style: GoogleFonts.inter(color: AppTheme.darkTextPri, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.alternate_email, size: 18),
                  ),
                ),
                const SizedBox(height: 16),

                AuthFieldLabel('Phone (optional)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                  style: GoogleFonts.inter(color: AppTheme.darkTextPri, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: '+20 1xx xxx xxxx',
                    prefixIcon: Icon(Icons.phone_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: 16),

                AuthFieldLabel('Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  validator: Validators.validatePassword,
                  style: GoogleFonts.inter(color: AppTheme.darkTextPri, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 18, color: AppTheme.darkTextSec),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                AuthFieldLabel('Confirm password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confCtrl,
                  obscureText: _obscureC,
                  validator: (v) => Validators.validateConfirmPassword(v, _passCtrl.text),
                  style: GoogleFonts.inter(color: AppTheme.darkTextPri, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureC ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 18, color: AppTheme.darkTextSec),
                      onPressed: () => setState(() => _obscureC = !_obscureC),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Risk preference picker
                AuthFieldLabel('Investment risk preference'),
                const SizedBox(height: 10),
                Row(children: [
                  for (final (value, label, color) in [
                    ('LOW',    'Low',    const Color(0xFF10B981)),
                    ('MEDIUM', 'Medium', const Color(0xFFF59E0B)),
                    ('HIGH',   'High',   AppTheme.errorColor),
                  ]) ...[
                    Expanded(child: GestureDetector(
                      onTap: () => setState(() => _riskPreference = value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _riskPreference == value
                              ? color.withValues(alpha: 0.15)
                              : AppTheme.darkElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _riskPreference == value
                                ? color
                                : AppTheme.darkBorder,
                            width: _riskPreference == value ? 1.5 : 1,
                          ),
                        ),
                        child: Column(children: [
                          Icon(Icons.trending_up, size: 16,
                              color: _riskPreference == value ? color : AppTheme.darkTextMuted),
                          const SizedBox(height: 4),
                          Text(label, style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: _riskPreference == value ? color : AppTheme.darkTextSec,
                          )),
                        ]),
                      ),
                    )),
                    if (value != 'HIGH') const SizedBox(width: 8),
                  ],
                ]),
                const SizedBox(height: 32),

                Consumer<AuthProvider>(builder: (_, auth, __) =>
                  GradientButton(label: 'Create Account', loading: auth.isLoading, onTap: _register)),
                const SizedBox(height: 20),

                Center(child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: RichText(text: TextSpan(children: [
                    TextSpan(text: 'Already have an account? ',
                      style: GoogleFonts.inter(color: AppTheme.darkTextSec, fontSize: 13)),
                    TextSpan(text: 'Sign In',
                      style: GoogleFonts.inter(
                        color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
                  ])),
                )),
                const SizedBox(height: 32),
              ],
            )),
          )),
        ])),
      ]),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color; final double size; final double opacity;
  const _Glow({required this.color, required this.size, required this.opacity});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color.withValues(alpha: opacity), Colors.transparent]),
    ),
  );
}
