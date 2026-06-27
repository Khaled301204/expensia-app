import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _selectedRisk;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameCtrl.text  = user.name;
      _phoneCtrl.text = user.phone ?? '';
      _selectedRisk   = user.riskPreference?.toUpperCase();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AuthProvider>();
    final ok = await provider.updateProfile(
      name:           _nameCtrl.text.trim(),
      phone:          _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      riskPreference: _selectedRisk,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to update profile')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        foregroundColor: AppTheme.darkTextPri,
        surfaceTintColor: Colors.transparent,
        title: Text('Profile', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [

          // Avatar + email block
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: Column(children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.4), width: 2),
                ),
                child: Center(child: Text(
                  (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : '?',
                  style: GoogleFonts.inter(
                    color: AppTheme.primaryColor, fontSize: 28, fontWeight: FontWeight.w700,
                  ),
                )),
              ),
              const SizedBox(height: 12),
              Text(user?.email ?? '',
                style: GoogleFonts.inter(color: AppTheme.darkTextSec, fontSize: 14)),
              const SizedBox(height: 4),
              if (user != null)
                Text('Member since ${DateFormat('MMM yyyy').format(user.createdAt)}',
                  style: GoogleFonts.inter(color: AppTheme.darkTextMuted, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 16),

          // Appearance
          Consumer<ThemeProvider>(builder: (_, themeProvider, __) =>
            Container(
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.darkBorder),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                secondary: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    themeProvider.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                    color: AppTheme.primaryColor, size: 20,
                  ),
                ),
                title: Text('Dark Mode',
                    style: GoogleFonts.inter(
                        color: AppTheme.darkTextPri,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                subtitle: Text(
                  themeProvider.isDarkMode ? 'Switch to light theme' : 'Switch to dark theme',
                  style: GoogleFonts.inter(color: AppTheme.darkTextMuted, fontSize: 12),
                ),
                value: themeProvider.isDarkMode,
                activeThumbColor: AppTheme.primaryColor,
                activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                onChanged: (_) => themeProvider.toggleTheme(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Edit form
          Form(key: _formKey, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              _Label('Full Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                style: GoogleFonts.inter(color: AppTheme.darkTextPri, fontSize: 14),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline, size: 18),
                  hintText: 'Your name',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Name is required';
                  if (v.trim().length < 2) return 'Name must be at least 2 characters';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _Label('Phone (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.inter(color: AppTheme.darkTextPri, fontSize: 14),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.phone_outlined, size: 18),
                  hintText: '+20 xxx xxx xxxx',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final phoneRegex = RegExp(r'^\+?[\d\s\-]{10,}$');
                  if (!phoneRegex.hasMatch(v.trim())) return 'Enter a valid phone number';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _Label('Risk Preference'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedRisk,
                isExpanded: true,
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.tune_outlined, size: 18)),
                hint: Text('Select risk level',
                    style: GoogleFonts.inter(color: AppTheme.darkTextMuted, fontSize: 14)),
                items: const [
                  DropdownMenuItem(value: 'LOW',    child: Text('Low')),
                  DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                  DropdownMenuItem(value: 'HIGH',   child: Text('High')),
                ],
                onChanged: (v) => setState(() => _selectedRisk = v),
              ),
              const SizedBox(height: 36),

              Consumer<AuthProvider>(builder: (_, provider, __) =>
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
                      onPressed: provider.isLoading ? null : _save,
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
        ]),
      ),
    );
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
