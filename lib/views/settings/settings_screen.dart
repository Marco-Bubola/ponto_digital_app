import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/session_service.dart';
import '../../services/theme_service.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'help_center_screen.dart';
import 'devices_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _darkMode = false;
  
  // Dados do usuário
  String _userName = 'Usuário';
  String _userEmail = 'usuario@empresa.com';
  String _companyName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Inicializar estado do switch de tema a partir do ThemeService
    _darkMode = ThemeService.themeModeNotifier.value == ThemeMode.dark;
    ThemeService.themeModeNotifier.addListener(() {
      if (mounted) {
        setState(() {
          _darkMode = ThemeService.themeModeNotifier.value == ThemeMode.dark;
        });
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      final user = await SessionService.getUser();
      if (user != null && mounted) {
        setState(() {
          _userName = user['name'] ?? 'Usuário';
          _userEmail = user['email'] ?? 'usuario@empresa.com';
          _companyName = (user['company'] != null && user['company']['name'] != null)
              ? user['company']['name']
              : '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      await SessionService.clear();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text('Erro ao fazer logout: $e'),
              ],
            ),
            backgroundColor: Color(AppColors.errorRed),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(AppColors.primaryBlue).withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header moderno com perfil do usuário
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(AppColors.primaryBlue),
                        Color(AppColors.secondaryTeal),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Color(AppColors.primaryBlue).withValues(alpha: 0.3),
                        spreadRadius: 2,
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.settings_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Configurações',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Personalize sua experiência',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Perfil do usuário
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Colors.white.withValues(alpha: 0.8),
                                  ],
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 35,
                                  color: Color(AppColors.primaryBlue),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _isLoading 
                                    ? const SizedBox(
                                        width: 150,
                                        height: 18,
                                        child: LinearProgressIndicator(
                                          backgroundColor: Colors.white24,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        _userName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                  const SizedBox(height: 4),
                                  _isLoading
                                    ? const SizedBox(
                                        width: 200,
                                        height: 14,
                                        child: LinearProgressIndicator(
                                          backgroundColor: Colors.white24,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                                        ),
                                      )
                                    : Text(
                                        _userEmail,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                      ),
                                  if (_companyName.isNotEmpty && !_isLoading) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _companyName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white60,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.verified_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Configurações organizadas em cards modernos
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Seção Conta
                      _ModernSettingsSection(
                        title: 'Conta',
                        icon: Icons.account_circle_rounded,
                        color: Color(AppColors.primaryBlue),
                        children: [
                          _ModernSettingsTile(
                            icon: Icons.edit_rounded,
                            title: 'Editar Perfil',
                            subtitle: 'Alterar dados pessoais',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditProfileScreen(),
                                ),
                              ).then((_) => _loadUserData()); // Recarregar dados ao voltar
                            },
                          ),
                          _ModernSettingsTile(
                            icon: Icons.lock_rounded,
                            title: 'Alterar Senha',
                            subtitle: 'Atualizar sua senha de acesso',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ChangePasswordScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Seção Notificações
                      _ModernSettingsSection(
                        title: 'Notificações',
                        icon: Icons.notifications_rounded,
                        color: Color(AppColors.warningYellow),
                        children: [
                          _ModernSwitchTile(
                            icon: Icons.notifications_active_rounded,
                            title: 'Notificações Push',
                            subtitle: 'Receber notificações do aplicativo',
                            value: _notificationsEnabled,
                            onChanged: (value) {
                              setState(() {
                                _notificationsEnabled = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Seção Segurança
                      _ModernSettingsSection(
                        title: 'Segurança',
                        icon: Icons.security_rounded,
                        color: Color(AppColors.successGreen),
                        children: [
                          _ModernSwitchTile(
                            icon: Icons.fingerprint_rounded,
                            title: 'Autenticação Biométrica',
                            subtitle: 'Usar digital ou face para acessar',
                            value: _biometricEnabled,
                            onChanged: (value) {
                              setState(() {
                                _biometricEnabled = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Seção Aparência
                      _ModernSettingsSection(
                        title: 'Aparência',
                        icon: Icons.palette_rounded,
                        color: Color(AppColors.secondaryTeal),
                        children: [
                          _ModernSwitchTile(
                            icon: Icons.dark_mode_rounded,
                            title: 'Modo Escuro',
                            subtitle: 'Ativar tema escuro do aplicativo',
                            value: _darkMode,
                            onChanged: (value) {
                              setState(() {
                                _darkMode = value;
                              });
                              // Aplicar e salvar preferência global
                              ThemeService.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Seção Suporte
                      _ModernSettingsSection(
                        title: 'Suporte',
                        icon: Icons.support_agent_rounded,
                        color: Color(AppColors.errorRed),
                        children: [
                          _ModernSettingsTile(
                            icon: Icons.help_center_rounded,
                            title: 'Central de Ajuda',
                            subtitle: 'FAQ e tutoriais',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HelpCenterScreen(),
                                ),
                              );
                            },
                          ),
                          _ModernSettingsTile(
                            icon: Icons.contact_support_rounded,
                            title: 'Fale Conosco',
                            subtitle: 'Entre em contato com o suporte',
                            onTap: () {
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
                          ),
                          _ModernSettingsTile(
                            icon: Icons.info_rounded,
                            title: 'Sobre o App',
                            subtitle: 'Versão ${AppConstants.appVersion}',
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: Row(
                                    children: [
                                      Icon(
                                        Icons.info_rounded,
                                        color: Color(AppColors.primaryBlue),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Sobre o App'),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Ponto Digital'),
                                      Text('Versão: ${AppConstants.appVersion}'),
                                      const SizedBox(height: 8),
                                      const Text('Desenvolvido para facilitar o controle de jornada de trabalho.'),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Fechar'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          _ModernSettingsTile(
                            icon: Icons.devices_rounded,
                            title: 'Gerenciar Dispositivos',
                            subtitle: 'Listar e remover dispositivos autorizados',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DevicesManagementScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Botão de logout moderno
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(AppColors.errorRed),
                              Color(AppColors.errorRed).withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Color(AppColors.errorRed).withValues(alpha: 0.3),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: Row(
                                    children: [
                                      Icon(
                                        Icons.logout_rounded,
                                        color: Color(AppColors.errorRed),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Sair do App'),
                                    ],
                                  ),
                                  content: const Text('Tem certeza que deseja sair do aplicativo?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _logout();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(AppColors.errorRed),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Sair'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.logout_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Sair do App',
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
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widgets modernos para configurações
class _ModernSettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _ModernSettingsSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header da seção
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Conteúdo da seção
          ...children,
        ],
      ),
    );
  }
}

class _ModernSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModernSettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ModernSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value ? Color(AppColors.primaryBlue).withValues(alpha: 0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: value ? Color(AppColors.primaryBlue) : Colors.grey[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Color(AppColors.primaryBlue),
          ),
        ],
      ),
    );
  }
}
