import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _password = '';
  String _cpf = '';
  String _role = 'user';

  final List<Map<String, String>> _roles = [
    {'label': 'Usuário', 'value': 'user'},
    {'label': 'Gestor', 'value': 'gestor'},
    {'label': 'Admin', 'value': 'admin'},
  ];

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Mapeamento de categoria para role do backend
      String backendRole;
      switch (_role) {
        case 'user':
          backendRole = 'employee';
          break;
        case 'gestor':
          backendRole = 'manager';
          break;
        case 'admin':
          backendRole = 'admin';
          break;
        default:
          backendRole = 'employee';
      }

      // Usar CPF dinâmico e companyId fixo para teste
      String companyId = '6510e1e2e2e2e2e2e2e2e2e2';

  final url = Uri.parse('${AppConstants.apiBase}/api/auth/register');
      final body = {
        'name': _name,
        'email': _email,
        'password': _password,
        'cpf': _cpf,
        'companyId': companyId,
        'role': backendRole,
      };

      try {
        final response = await http.post(url, 
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        );
        
        if (!mounted) return;
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cadastro realizado com sucesso!')),
          );
          if (!mounted) return;
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao cadastrar: ${response.body}')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de conexão: $e')),
        );
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
              Color(0xFF1565C0), // Azul principal
              Color(0xFF00BFAE), // Teal secundário
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
                  Container(
                    width: 120,
                    height: 120,
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
                          color: Color.fromARGB(38, 0, 0, 0),
                          spreadRadius: 2,
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person_add_rounded,
                      size: 70,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Cadastro de Usuário',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Preencha os dados para criar sua conta',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Color.fromARGB(230, 255, 255, 255),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromARGB(20, 0, 0, 0),
                          spreadRadius: 1,
                          blurRadius: 12,
                          offset: const Offset(0, 4),
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
                                  Icons.person_rounded,
                                  color: Color(0xFF1565C0),
                                  size: 28,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Dados do usuário',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: Color(0xFF222222),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Nome',
                                  prefixIcon: Icon(Icons.person_outline_rounded, color: Color(0xFF1565C0)),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(20),
                                ),
                                validator: (value) => value == null || value.isEmpty ? 'Informe o nome' : null,
                                onSaved: (value) => _name = value ?? '',
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'E-mail',
                                  prefixIcon: Icon(Icons.email_rounded, color: Color(0xFF1565C0)),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(20),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) => value == null || !value.contains('@') ? 'Informe um e-mail válido' : null,
                                onSaved: (value) => _email = value ?? '',
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'CPF',
                                  hintText: '000.000.000-00',
                                  prefixIcon: Icon(Icons.badge_rounded, color: Color(0xFF1565C0)),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(20),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Informe o CPF';
                                  }
                                  if (value.length < 11) {
                                    return 'CPF deve ter 11 dígitos';
                                  }
                                  return null;
                                },
                                onSaved: (value) => _cpf = value ?? '',
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Senha',
                                  prefixIcon: Icon(Icons.lock_rounded, color: Color(0xFF1565C0)),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(20),
                                ),
                                obscureText: true,
                                validator: (value) => value == null || value.length < 6 ? 'Senha deve ter ao menos 6 caracteres' : null,
                                onSaved: (value) => _password = value ?? '',
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: DropdownButtonFormField<String>(
                                initialValue: _role,
                                decoration: const InputDecoration(
                                  labelText: 'Categoria',
                                  prefixIcon: Icon(Icons.verified_user_rounded, color: Color(0xFF1565C0)),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(20),
                                ),
                                items: _roles.map((role) => DropdownMenuItem(
                                  value: role['value'],
                                  child: Text(role['label']!),
                                )).toList(),
                                onChanged: (value) => setState(() => _role = value ?? 'user'),
                                onSaved: (value) => _role = value ?? 'user',
                              ),
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF1565C0),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                              onPressed: _submit,
                              label: const Text('Cadastrar', style: TextStyle(fontSize: 18, color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
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

