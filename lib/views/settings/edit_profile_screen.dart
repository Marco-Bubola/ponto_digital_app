import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/constants.dart';
import '../../services/session_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cpfController = TextEditingController();
  final _roleController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await SessionService.getUser();
      if (user != null && mounted) {
        setState(() {
          _nameController.text = user['name'] ?? '';
          _emailController.text = user['email'] ?? '';
          _phoneController.text = user['phone'] ?? '';
          _cpfController.text = user['cpf'] ?? '';
          _roleController.text = user['role'] ?? '';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      // Simulate save (replace with real API call)
      await Future.delayed(const Duration(seconds: 1));
      final user = await SessionService.getUser();
      if (user != null) {
        user['name'] = _nameController.text;
        user['email'] = _emailController.text;
        user['phone'] = _phoneController.text;
        user['cpf'] = _cpfController.text;
        user['role'] = _roleController.text;
        await SessionService.saveUser(user);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: const [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Text('Perfil atualizado com sucesso!')]),
          backgroundColor: Color(AppColors.successGreen),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Color(AppColors.errorRed),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Header
                        Container(
                          margin: const EdgeInsets.only(bottom: 18),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer.withValues(alpha: 0.9)]),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: theme.shadowColor.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
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
                            const SizedBox(width: 8),
                            CircleAvatar(radius: 36, backgroundColor: theme.colorScheme.surface, child: Icon(Icons.person_rounded, size: 36, color: theme.colorScheme.primary)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(_nameController.text.isNotEmpty ? _nameController.text : 'Seu nome', style: TextStyle(color: Colors.white.withValues(alpha: 1.0), fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(_emailController.text.isNotEmpty ? _emailController.text : 'seu@email.com', style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 13)),
                                const SizedBox(height: 8),
                                Row(children: [
                                  if (_roleController.text.isNotEmpty) Text(_roleController.text, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
                                  if (_roleController.text.isNotEmpty) const SizedBox(width: 10),
                                  if (_cpfController.text.isNotEmpty) Text('CPF: ${_cpfController.text}', style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 12)),
                                ])
                              ]),
                            )
                          ]),
                        ),

                        // Form
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: theme.colorScheme.onSurface.withValues(alpha: 0.06), spreadRadius: 1, blurRadius: 8, offset: const Offset(0, 2))]),
                          child: Column(children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(labelText: 'Nome', prefixIcon: const Icon(Icons.person_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                              validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(labelText: 'Email', prefixIcon: const Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Campo obrigatório';
                                 if (!RegExp(r'^[\w\.\-]+@[A-Za-z0-9\.\-]+\.[A-Za-z]{2,}').hasMatch(value)) return 'Email inválido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly, _PhoneNumberFormatter()],
                              decoration: InputDecoration(labelText: 'Telefone', prefixIcon: const Icon(Icons.phone_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _cpfController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly, _CpfInputFormatter()],
                              decoration: InputDecoration(labelText: 'CPF', prefixIcon: const Icon(Icons.badge_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                              validator: (value) {
                                final v = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                                if (v.isEmpty) return null; // optional
                                if (!_validateCpf(v)) return 'CPF inválido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(controller: _roleController, decoration: InputDecoration(labelText: 'Cargo', prefixIcon: const Icon(Icons.work_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                            const SizedBox(height: 32),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 2),
              child: _isSaving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Salvar Alterações', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cpfController.dispose();
    _roleController.dispose();
    super.dispose();
  }
}

// CPF validator and input formatters
bool _validateCpf(String cpf) {
  if (cpf.length != 11) return false;
  final invalids = List<String>.generate(10, (i) => List.filled(11, i.toString()).join());
  if (invalids.contains(cpf)) return false;

  int calc(List<int> nums) {
    int sum = 0;
    for (int i = 0; i < nums.length; i++) {
      sum += nums[i] * (nums.length + 1 - i);
    }
    final mod = sum % 11;
    return mod < 2 ? 0 : 11 - mod;
  }

  try {
    final digits = cpf.split('').map(int.parse).toList();
    final d1 = calc(digits.sublist(0, 9));
    if (d1 != digits[9]) return false;
    final d2 = calc([...digits.sublist(0, 9), d1]);
    if (d2 != digits[10]) return false;
    return true;
  } catch (_) {
    return false;
  }
}

class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 11; i++) {
      buffer.write(digits[i]);
      if (i == 2 || i == 5) buffer.write('.');
      if (i == 8) buffer.write('-');
    }
    final text = buffer.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    String formatted;
    if (digits.length <= 2) {
      formatted = '($digits';
    } else if (digits.length <= 6) {
      formatted = '(${digits.substring(0, 2)}) ${digits.substring(2)}';
    } else if (digits.length <= 10) {
      formatted = '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    } else {
      final d = digits.substring(0, 11);
      formatted = '(${d.substring(0, 2)}) ${d.substring(2, 7)}-${d.substring(7)}';
    }
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}
