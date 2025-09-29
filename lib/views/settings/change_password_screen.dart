import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSaving = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Simular mudança de senha (aqui você faria uma chamada à API)
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Senha alterada com sucesso!'),
              ],
            ),
            backgroundColor: Color(AppColors.successGreen),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao alterar senha: $e'),
            backgroundColor: Color(AppColors.errorRed),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [theme.colorScheme.primary.withValues(alpha: 0.06), theme.scaffoldBackgroundColor]),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer.withValues(alpha: 0.9)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(padding: const EdgeInsets.all(8), child: Icon(Icons.arrow_back_rounded, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: theme.colorScheme.surface, shape: BoxShape.circle), child: Icon(Icons.lock_outline_rounded, color: theme.colorScheme.primary, size: 36)),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Alterar Senha', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold))),
                ]),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  child: Form(
                    key: _formKey,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: theme.shadowColor.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                      child: Column(children: [
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: !_showCurrentPassword,
                          decoration: InputDecoration(labelText: 'Senha Atual', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_showCurrentPassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _showCurrentPassword = !_showCurrentPassword)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          validator: (value) => (value == null || value.isEmpty) ? 'Campo obrigatório' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: !_showNewPassword,
                          decoration: InputDecoration(labelText: 'Nova Senha', prefixIcon: const Icon(Icons.lock), suffixIcon: IconButton(icon: Icon(_showNewPassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _showNewPassword = !_showNewPassword)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Campo obrigatório';
                            if (value.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_showConfirmPassword,
                          decoration: InputDecoration(labelText: 'Confirmar Nova Senha', prefixIcon: const Icon(Icons.lock), suffixIcon: IconButton(icon: Icon(_showConfirmPassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Campo obrigatório';
                            if (value != _newPasswordController.text) return 'As senhas não coincidem';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        // small hint
                        Row(children: [Icon(Icons.info_outline, size: 16, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7)), const SizedBox(width: 8), Expanded(child: Text('A senha deve ter no mínimo 6 caracteres.', style: theme.textTheme.bodySmall))])
                      ]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _changePassword,
              style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 2),
              child: _isSaving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Alterar Senha', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}