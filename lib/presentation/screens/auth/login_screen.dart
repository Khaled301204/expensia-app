import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/config/theme.dart';
import '../../../core/utils/validators.dart';
import '../../../routes/app_router.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(email: _emailCtrl.text.trim(), password: _passCtrl.text);
    if (!mounted) return;
    if (ok) { Navigator.pushReplacementNamed(context, AppRouter.home); }
    else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error ?? 'Login failed'),
        backgroundColor: AppTheme.errorColor,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Stack(children: [
        Positioned(top: -120, left: -120,
          child: _GlowCircle(color: AppTheme.primaryColor, size: 340, opacity: 0.18)),
        Positioned(bottom: -80, right: -80,
          child: _GlowCircle(color: AppTheme.accentOrange, size: 260, opacity: 0.12)),
        SafeArea(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(key: _formKey, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 52),

              // "AI-Powered Finance" badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 6, height: 6,
                    decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('AI-Powered Finance', style: GoogleFonts.inter(
                    color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w500,
                  )),
                ]),
              ),
              const SizedBox(height: 24),

              // Big gradient heading
              RichText(text: TextSpan(children: [
                TextSpan(text: 'Sign in to\n', style: GoogleFonts.inter(
                  color: AppTheme.darkTextPri, fontSize: 36,
                  fontWeight: FontWeight.w800, letterSpacing: -1.2, height: 1.1,
                )),
                TextSpan(text: 'Expensia', style: GoogleFonts.inter(
                  fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.2, height: 1.1,
                  foreground: Paint()..shader = const LinearGradient(
                    colors: [AppTheme.primaryLight, AppTheme.accentPurple, AppTheme.accentOrange],
                  ).createShader(const Rect.fromLTWH(0, 0, 220, 40)),
                )),
              ])),
              const SizedBox(height: 12),
              Text('Manage your finances with AI intelligence', style: GoogleFonts.inter(
                color: AppTheme.darkTextSec, fontSize: 14, height: 1.5,
              )),
              const SizedBox(height: 40),

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
              const SizedBox(height: 18),

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
              const SizedBox(height: 32),

              Consumer<AuthProvider>(builder: (_, auth, __) => GradientButton(
                label: 'Sign In', loading: auth.isLoading, onTap: _login,
              )),
              const SizedBox(height: 24),

              Row(children: [
                const Expanded(child: Divider(color: AppTheme.darkBorder)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('or', style: GoogleFonts.inter(
                    color: AppTheme.darkTextMuted, fontSize: 13))),
                const Expanded(child: Divider(color: AppTheme.darkBorder)),
              ]),
              const SizedBox(height: 24),

              SizedBox(width: double.infinity, height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, AppRouter.register),
                  child: Text('Create an account', style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.darkTextPri,
                  )),
                ),
              ),
              const SizedBox(height: 40),

              // Stats strip
              Row(children: [
                for (final s in [
                  ('AI Insights', '24/7',    AppTheme.primaryColor),
                  ('Accuracy',   '99%',      AppTheme.accentPurple),
                  ('Secure',     '256-bit',  AppTheme.secondaryColor),
                ])
                  Expanded(child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.darkBorder),
                    ),
                    child: Column(children: [
                      Text(s.$2, style: GoogleFonts.inter(
                        color: s.$3, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5,
                      )),
                      const SizedBox(height: 3),
                      Text(s.$1, style: GoogleFonts.inter(
                        color: AppTheme.darkTextSec, fontSize: 11,
                      )),
                    ]),
                  )),
              ]),
              const SizedBox(height: 32),
            ],
          )),
        )),
      ]),
    );
  }
}

// ── Shared auth widgets (used by both login + register) ───────────────────────

class _GlowCircle extends StatelessWidget {
  final Color color; final double size; final double opacity;
  const _GlowCircle({required this.color, required this.size, required this.opacity});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color.withValues(alpha: opacity), Colors.transparent]),
    ),
  );
}

class AuthFieldLabel extends StatelessWidget {
  final String text;
  const AuthFieldLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(text, style: GoogleFonts.inter(
    color: AppTheme.darkTextSec, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.2,
  ));
}

class GradientButton extends StatelessWidget {
  final String label; final bool loading; final VoidCallback onTap;
  const GradientButton({super.key, required this.label, required this.loading, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: Container(
      height: 52, width: double.infinity,
      decoration: BoxDecoration(
        gradient: loading ? null : const LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primaryColor],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        color: loading ? AppTheme.darkElevated : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: loading ? [] : [AppTheme.blueGlow],
      ),
      child: Center(child: loading
        ? const SizedBox(width: 20, height: 20,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
        : Text(label, style: GoogleFonts.inter(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    ),
  );
}
