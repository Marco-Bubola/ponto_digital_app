import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../services/device_service.dart';
import '../../utils/constants.dart';
import '../../services/session_service.dart';

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
  // Dados reais do usuário (fallbacks)
  String _lastRecordTitle = 'Nenhum registro';
  String _lastRecordSubtitle = '';
  String _lastRecordStatus = 'Pendente';
  List<Map<String, dynamic>> _records = [];
  bool _isLoadingRecords = false;
  String? _recordsError;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _getCurrentLocation();
    _loadSessionData();
    _fetchTimeRecords();
    // Atualizar o tempo a cada segundo
    Future.delayed(const Duration(seconds: 1), _updateTime);
  }

  Future<void> _fetchTimeRecords() async {
    setState(() {
      _isLoadingRecords = true;
      _recordsError = null;
    });

    try {
      final token = await SessionService.getToken();
      final deviceId = await DeviceService.getDeviceId();
      final uri = Uri.parse('http://localhost:3000/api/time-records');
      final resp = await http.get(uri, headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'X-Device-ID': deviceId,
      });

      if (resp.statusCode == 200) {
        final body = json.decode(resp.body) as Map<String, dynamic>;
        final recs = (body['records'] as List<dynamic>?) ?? [];
          if (mounted) {
            setState(() {
            _records = recs.map((r) => Map<String, dynamic>.from(r as Map)).toList();
            if (_records.isNotEmpty) {
              final first = _records.first;
              final entry = first['type'] ?? '—';
              final timeRaw = first['timestamp'] ?? first['createdAt'] ?? '';
              String time = timeRaw.toString();
              try {
                final dt = DateTime.parse(timeRaw.toString());
                time = DateFormat('HH:mm', 'pt_BR').format(dt);
              } catch (_) {}
              _lastRecordTitle = entry.toString();
              _lastRecordSubtitle = time;
              _lastRecordStatus = first['overallStatus'] ?? _lastRecordStatus;
            }
          });
          }
      } else {
        setState(() {
          _recordsError = 'Erro ao buscar registros: ${resp.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _recordsError = 'Falha de conexão';
      });
    } finally {
      if (mounted) setState(() => _isLoadingRecords = false);
    }
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        final now = DateTime.now();
        _currentTime = DateFormat('HH:mm:ss', 'pt_BR').format(now);
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
            // se o usuário na sessão tiver localização preferida, usar
            // (será sobrescrito depois se houver dados reais)
        });
      }
    });
  }


  Future<void> _loadSessionData() async {
    try {
      final user = await SessionService.getUser();
      if (user == null) return;

      // Localização preferencial do usuário
      if (user['preferredLocation'] != null) {
        final loc = user['preferredLocation'];
        if (loc is String && loc.isNotEmpty) {
          if (mounted) setState(() => _currentLocation = loc);
        } else if (loc is Map) {
          final locStr = '${loc['name'] ?? ''} ${loc['city'] ?? ''}'.trim();
          if (locStr.isNotEmpty && mounted) setState(() => _currentLocation = locStr);
        }
      }

      // Hoje
      final today = user['today'];
      if (today != null && today is Map) {
        final entry = today['entryTime'] as String?;
        final exit = today['exitTime'] as String?;
        if (entry != null && entry.isNotEmpty) {
          if (mounted) {
            setState(() => _lastRecordTitle = 'Entrada - $entry');
          }
        }
        if (exit != null && exit.isNotEmpty) {
          if (mounted) {
            setState(() => _lastRecordTitle = _lastRecordTitle.startsWith('Entrada') ? _lastRecordTitle : 'Saída - $exit');
          }
        }
        final loc = today['location'] as String?;
        if (loc != null && loc.isNotEmpty) {
          if (mounted) {
            setState(() {
              _lastRecordSubtitle = 'Hoje - $loc';
            });
          }
        }
        final confirmed = today['confirmed'];
        if (confirmed != null) {
          if (mounted) {
            setState(() {
              _lastRecordStatus = confirmed == true ? 'Confirmado' : 'Pendente';
            });
          }
        }
      }

      // Registros recentes
      final recs = user['recentRecords'];
      if (recs == null || (recs is List && recs.isEmpty)) {
        if (mounted) {
          // fallback: usar dados estáticos já definidos
        }
      } else if (recs is List && recs.isNotEmpty) {
        final r = recs.first;
        final date = r['date'] ?? '—';
        final entry = r['entry'] ?? '--:--';
        if (mounted) {
          setState(() {
          _lastRecordTitle = 'Entrada - $entry';
          _lastRecordSubtitle = '$date - ${r['location'] ?? _currentLocation}';
          _lastRecordStatus = (r['confirmed'] == true) ? 'Confirmado' : 'Pendente';
        });
        }
      }
    } catch (e) {
      // ignore errors, manter fallback
    }
  }
  String _getFormattedDate() {
    final now = DateTime.now();
    final df = DateFormat("EEEE, d 'de' MMMM", 'pt_BR');
    return toBeginningOfSentenceCase(df.format(now)) ?? df.format(now);
  }

  Future<void> _recordTimecard(TimeRecordType type) async {
    setState(() {
      _isRecording = true;
      _currentAction = type;
    });

    try {
      // Obter token
      final token = await SessionService.getToken();

      // Simular obtenção de localização e face
      await Future.delayed(const Duration(seconds: 1));
      final latitude = -23.55052;
      final longitude = -46.633308;

      // Chamar endpoint backend
      final deviceId = await DeviceService.getDeviceId();
      final uri = Uri.parse('http://localhost:3000/api/time-records');
      var resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          'X-Device-ID': deviceId,
          'X-Device-Name': 'FlutterApp',
          'X-Platform': 'flutter',
          'X-App-Version': '1.0.0'
        },
        body: json.encode({
          'type': type.name,
          'latitude': latitude,
          'longitude': longitude,
          'faceImageUrl': null,
        }),
      );

      if (resp.statusCode == 401) {
        // Possível dispositivo não autorizado -> tentar autorizar e reenviar
        final body = resp.body;
        if (body.contains('Dispositivo não autorizado') || body.contains('ID do dispositivo necessário')) {
          final deviceId = await DeviceService.getDeviceId();
          final authUri = Uri.parse('http://localhost:3000/api/users/devices');
          final authResp = await http.post(
            authUri,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token'
            },
            body: json.encode({ 'deviceId': deviceId, 'deviceName': 'FlutterApp' })
          );

          if (authResp.statusCode == 201 || authResp.statusCode == 200) {
            // reenviar o registro uma vez
            final retryResp = await http.post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                if (token != null) 'Authorization': 'Bearer $token',
                'X-Device-ID': deviceId,
                'X-Device-Name': 'FlutterApp',
                'X-Platform': 'flutter',
                'X-App-Version': '1.0.0'
              },
              body: json.encode({
                'type': type.name,
                'latitude': latitude,
                'longitude': longitude,
                'faceImageUrl': null,
              }),
            );

            if (retryResp.statusCode != 201 && retryResp.statusCode != 200) {
              throw Exception('Erro backend após autorizar dispositivo: ${retryResp.statusCode} ${retryResp.body}');
            }
            // usar a resposta do retry como resposta final
            resp = retryResp;

          } else {
            throw Exception('Falha ao autorizar dispositivo: ${authResp.statusCode} ${authResp.body}');
          }
        } else {
          throw Exception('Erro backend: ${resp.statusCode} ${resp.body}');
        }
      } else if (resp.statusCode != 201 && resp.statusCode != 200) {
        throw Exception('Erro backend: ${resp.statusCode} ${resp.body}');
      }

  json.decode(resp.body);

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

        // Atualizar estado local com novo registro mínimo
        if (mounted) {
          // Recarregar registros reais do backend para refletir alteração
          await _fetchTimeRecords();
        }
        setState(() {
          final now = DateTime.now();
          final ts = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
          _lastRecordTitle = '${_getTypeDisplayName(type)} - $ts';
          _lastRecordSubtitle = 'Agora - $_currentLocation';
          _lastRecordStatus = 'Confirmado';
        });
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

  // Retorna apenas os registros do dia atual (comparando year, month, day)
  List<Map<String, dynamic>> _recordsToday() {
    final today = DateTime.now();
    return _records.where((r) {
      final ts = r['timestamp'] ?? r['createdAt'];
      if (ts == null) return false;
      try {
        final dt = DateTime.parse(ts.toString()).toLocal();
        return dt.year == today.year && dt.month == today.month && dt.day == today.day;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  bool _isButtonEnabled(TimeRecordType type) {
    // Se já houve saída, nada mais deve ser registrado hoje
    final todayRecords = _recordsToday();
    final hasEntrada = todayRecords.any((r) => (r['type'] ?? r['entry'] ?? '').toString().toLowerCase() == 'entrada');
    final hasPausa = todayRecords.any((r) => (r['type'] ?? r['entry'] ?? '').toString().toLowerCase() == 'pausa');
    final hasRetorno = todayRecords.any((r) => (r['type'] ?? r['entry'] ?? '').toString().toLowerCase() == 'retorno');
    final hasSaida = todayRecords.any((r) => (r['type'] ?? r['entry'] ?? '').toString().toLowerCase() == 'saida');

    if (_isRecording) return false;
    if (hasSaida) return false;

    switch (type) {
      case TimeRecordType.entrada:
        // Só pode registrar entrada se não houver entrada hoje
        return !hasEntrada;
      case TimeRecordType.pausa:
        // Pausa só se houver entrada e ainda não houver pausa
        return hasEntrada && !hasPausa;
      case TimeRecordType.retorno:
        // Retorno só se já houve pausa e ainda não houve retorno
        return hasPausa && !hasRetorno;
      case TimeRecordType.saida:
        // Saída se já houve entrada e ainda não houve saída
        return hasEntrada && !hasSaida;
    }
  }

  String _disabledReason(TimeRecordType type) {
    final todayRecords = _recordsToday();
    final hasEntrada = todayRecords.any((r) => (r['type'] ?? r['entry'] ?? '').toString().toLowerCase() == 'entrada');
    final hasPausa = todayRecords.any((r) => (r['type'] ?? r['entry'] ?? '').toString().toLowerCase() == 'pausa');
    final hasRetorno = todayRecords.any((r) => (r['type'] ?? r['entry'] ?? '').toString().toLowerCase() == 'retorno');
    final hasSaida = todayRecords.any((r) => (r['type'] ?? r['entry'] ?? '').toString().toLowerCase() == 'saida');

    if (_isRecording) return 'Já está registrando...';
    if (hasSaida) return 'Jornada finalizada (saída registrada)';

    switch (type) {
      case TimeRecordType.entrada:
        return hasEntrada ? 'Entrada já registrada' : 'Registrar entrada';
      case TimeRecordType.pausa:
        if (!hasEntrada) return 'Registre a entrada primeiro';
        return hasPausa ? 'Pausa já registrada' : 'Registrar pausa';
      case TimeRecordType.retorno:
        if (!hasPausa) return 'Nenhuma pausa registrada';
        return hasRetorno ? 'Retorno já registrado' : 'Registrar retorno';
      case TimeRecordType.saida:
        if (!hasEntrada) return 'Registre a entrada primeiro';
        return hasSaida ? 'Saída já registrada' : 'Registrar saída';
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
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Refresh / estado
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_isLoadingRecords) const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _isLoadingRecords ? null : () async => await _fetchTimeRecords(),
                    ),
                  ],
                ),
                if (_recordsError != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(AppColors.errorRed).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_recordsError!, style: TextStyle(color: Color(AppColors.errorRed))),
                  ),
                // ...existing code...
                
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
                                  color: Colors.white.withValues(alpha: 0.8),
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
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Horário Atual',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
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
                        color: Colors.grey.withValues(alpha: 0.1),
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
                          color: Color(AppColors.successGreen).withValues(alpha: 0.1),
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
                          Color(AppColors.warningYellow).withValues(alpha: 0.1),
                          Colors.white,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Color(AppColors.warningYellow).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(AppColors.primaryBlue).withValues(alpha: 0.1),
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
                
                // Botões de ação modernos em linha única com validações de fluxo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: TimeRecordType.values.map((type) {
                    final enabled = _isButtonEnabled(type);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Tooltip(
                          message: enabled ? _getTypeDisplayName(type) : _disabledReason(type),
                          child: Opacity(
                            opacity: enabled ? 1.0 : 0.45,
                            child: _ModernTimecardButton(
                              type: type,
                              emoji: _getTypeEmoji(type),
                              icon: _getTypeIcon(type),
                              label: _getTypeDisplayName(type),
                              color: _getTypeColor(type),
                              isEnabled: enabled,
                              onPressed: enabled ? () => _recordTimecard(type) : null,
                            ),
                          ),
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
                        color: Colors.grey.withValues(alpha: 0.1),
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
                              color: Color(AppColors.successGreen).withValues(alpha: 0.1),
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
                                Text(
                                  _lastRecordTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _lastRecordSubtitle.isNotEmpty ? _lastRecordSubtitle : 'Hoje - $_currentLocation',
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
                              color: Color(AppColors.successGreen).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _lastRecordStatus,
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
  final VoidCallback? onPressed;

  const _ModernTimecardButton({
    required this.type,
    required this.emoji,
    required this.icon,
    required this.label,
    required this.color,
  required this.isEnabled,
  this.onPressed,
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
                  color.withValues(alpha: 0.8),
                ],
              )
            : LinearGradient(
                colors: [Colors.grey[300]!, Colors.grey[400]!],
              ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
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

