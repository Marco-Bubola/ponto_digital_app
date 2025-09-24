import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class TimecardScreen extends StatefulWidget {
  const TimecardScreen({super.key});

  @override
  State<TimecardScreen> createState() => _TimecardScreenState();
}

class _TimecardScreenState extends State<TimecardScreen> {
  TimeRecordType? _currentAction;
  bool _isRecording = false;
  String _currentTime = '';
  String _currentLocation = 'Carregando localização...';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _getCurrentLocation();
    // Atualizar o tempo a cada segundo
    Future.delayed(const Duration(seconds: 1), _updateTime);
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        final now = DateTime.now();
        _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      });
      Future.delayed(const Duration(seconds: 1), _updateTime);
    }
  }

  void _getCurrentLocation() {
    // Simular obtenção de localização
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _currentLocation = 'Escritório Central - São Paulo, SP';
        });
      }
    });
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final weekdays = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
    final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 
                   'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  Future<void> _recordTimecard(TimeRecordType type) async {
    setState(() {
      _isRecording = true;
      _currentAction = type;
    });

    try {
      // Simular processo de validação (Face + GPS + Device)
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text('${_getTypeDisplayName(type)} registrado com sucesso!'),
              ],
            ),
            backgroundColor: Color(AppColors.successGreen),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar: $error'),
            backgroundColor: Color(AppColors.errorRed),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _currentAction = null;
        });
      }
    }
  }

  String _getTypeDisplayName(TimeRecordType type) {
    switch (type) {
      case TimeRecordType.entrada:
        return 'Entrada';
      case TimeRecordType.pausa:
        return 'Pausa';
      case TimeRecordType.retorno:
        return 'Retorno';
      case TimeRecordType.saida:
        return 'Saída';
    }
  }

  String _getTypeEmoji(TimeRecordType type) {
    switch (type) {
      case TimeRecordType.entrada:
        return '🌅';
      case TimeRecordType.pausa:
        return '☕';
      case TimeRecordType.retorno:
        return '💼';
      case TimeRecordType.saida:
        return '🌙';
    }
  }

  IconData _getTypeIcon(TimeRecordType type) {
    switch (type) {
      case TimeRecordType.entrada:
        return Icons.login_rounded;
      case TimeRecordType.pausa:
        return Icons.pause_circle_rounded;
      case TimeRecordType.retorno:
        return Icons.play_circle_rounded;
      case TimeRecordType.saida:
        return Icons.logout_rounded;
    }
  }

  Color _getTypeColor(TimeRecordType type) {
    switch (type) {
      case TimeRecordType.entrada:
        return Color(AppColors.successGreen);
      case TimeRecordType.pausa:
        return Color(AppColors.warningYellow);
      case TimeRecordType.retorno:
        return Color(AppColors.primaryBlue);
      case TimeRecordType.saida:
        return Color(AppColors.secondaryTeal);
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
              Color(AppColors.primaryBlue).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Header moderno
                Container(
                  width: double.infinity,
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
                        color: Color(AppColors.primaryBlue).withOpacity(0.3),
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
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.fingerprint_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Registro de Ponto',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _getFormattedDate(),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Relógio principal moderno
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Horário Atual',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _currentTime,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 56,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Status de localização moderno
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(AppColors.successGreen).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          color: Color(AppColors.successGreen),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Localização Verificada',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentLocation,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.check_circle_rounded,
                        color: Color(AppColors.successGreen),
                        size: 24,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Status de validação
                if (_isRecording) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(AppColors.warningYellow).withOpacity(0.1),
                          Colors.white,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Color(AppColors.warningYellow).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(AppColors.primaryBlue).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(AppColors.primaryBlue),
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Registrando ${_getTypeDisplayName(_currentAction!)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Validando identidade e localização...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Título dos botões
                Row(
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      color: Color(AppColors.primaryBlue),
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Selecione o tipo de registro',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Botões de ação modernos em linha única
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: TimeRecordType.values.map((type) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: _ModernTimecardButton(
                          type: type,
                          emoji: _getTypeEmoji(type),
                          icon: _getTypeIcon(type),
                          label: _getTypeDisplayName(type),
                          color: _getTypeColor(type),
                          isEnabled: !_isRecording,
                          onPressed: () => _recordTimecard(type),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                
                // Último registro moderno
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey[50]!,
                        Colors.white,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.history_rounded,
                            color: Color(AppColors.primaryBlue),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Último Registro',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(AppColors.successGreen).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.login_rounded,
                              color: Color(AppColors.successGreen),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Entrada - 08:00',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Hoje - Escritório Central',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Color(AppColors.successGreen).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Confirmado',
                              style: TextStyle(
                                color: Color(AppColors.successGreen),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernTimecardButton extends StatelessWidget {
  final TimeRecordType type;
  final String emoji;
  final IconData icon;
  final String label;
  final Color color;
  final bool isEnabled;
  final VoidCallback onPressed;

  const _ModernTimecardButton({
    required this.type,
    required this.emoji,
    required this.icon,
    required this.label,
    required this.color,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: isEnabled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
              )
            : LinearGradient(
                colors: [Colors.grey[300]!, Colors.grey[400]!],
              ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(height: 8),
                Icon(
                  icon,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
