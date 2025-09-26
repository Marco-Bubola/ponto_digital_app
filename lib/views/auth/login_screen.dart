import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../dashboard/dashboard_screen.dart';
import 'register_screen.dart';
import '../../utils/constants.dart';
import '../../services/session_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
  final url = Uri.parse('${AppConstants.apiBase}/api/auth/login');
      final body = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'deviceId': 'web-device-001',
        'deviceName': 'Flutter Web'
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Salvar token e usuário na sessão
        final token = responseData['token'];
        final user = responseData['user'];
        if (token != null) await SessionService.saveToken(token);
        if (user != null) await SessionService.saveUser(user);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      } else {
        final errorData = json.decode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorData['error'] ?? 'Erro no login'),
              backgroundColor: Color(AppColors.errorRed),
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro de conexão: $error'),
            backgroundColor: Color(AppColors.errorRed),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(AppColors.primaryBlue),
              Color.fromARGB(204, (AppColors.primaryBlue >> 16) & 0xFF, (AppColors.primaryBlue >> 8) & 0xFF, AppColors.primaryBlue & 0xFF),
              Color(AppColors.secondaryTeal),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo e título modernos
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Color.fromARGB(230, 255, 255, 255),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromARGB(51, 0, 0, 0),
                          spreadRadius: 2,
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.fingerprint_rounded,
                      size: 80,
                      color: Color(AppColors.primaryBlue),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  Text(
                    'Ponto Digital',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 36,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    'Controle de jornada inteligente 🚀',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Color.fromARGB(230, 255, 255, 255),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Formulário de login moderno
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromARGB(26, 0, 0, 0),
                          spreadRadius: 1,
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.login_rounded,
                                  color: Color(AppColors.primaryBlue),
                                  size: 28,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Faça seu login',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: Color(AppColors.darkGray),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            
                            // Campo de email moderno
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'seu.email@empresa.com',
                                  prefixIcon: Icon(
                                    Icons.email_rounded,
                                    color: Color(AppColors.primaryBlue),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(20),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Digite seu email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Digite um email válido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Campo de senha moderno
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Senha',
                                  hintText: 'Digite sua senha',
                                  prefixIcon: Icon(
                                    Icons.lock_rounded,
                                    color: Color(AppColors.primaryBlue),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      color: Color(AppColors.neutralGray),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(20),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Digite sua senha';
                                  }
                                  if (value.length < 6) {
                                    return 'Senha deve ter pelo menos 6 caracteres';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Botão de login moderno
                            Container(
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(AppColors.primaryBlue),
                                    Color(AppColors.secondaryTeal),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color.fromARGB(77, (AppColors.primaryBlue >> 16) & 0xFF, (AppColors.primaryBlue >> 8) & 0xFF, AppColors.primaryBlue & 0xFF),
                                    spreadRadius: 1,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isLoading ? null : _handleLogin,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Center(
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.login_rounded,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Entrar',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Link esqueci a senha moderno
                            TextButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.info_outline, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text('Funcionalidade em desenvolvimento'),
                                      ],
                                    ),
                                    backgroundColor: Color(AppColors.warningYellow),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.help_outline_rounded,
                                color: Color(AppColors.primaryBlue),
                                size: 20,
                              ),
                              label: Text(
                                'Esqueci minha senha',
                                style: TextStyle(
                                  color: Color(AppColors.primaryBlue),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterScreen(),
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.person_add_rounded,
                                color: Color(AppColors.primaryBlue),
                                size: 20,
                              ),
                              label: Text(
                                'Cadastre-se',
                                style: TextStyle(
                                  color: Color(AppColors.primaryBlue),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Informações da versão modernas
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(51, 255, 255, 255),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Color.fromARGB(204, 255, 255, 255),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Versão ${AppConstants.appVersion}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Color.fromARGB(204, 255, 255, 255),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
