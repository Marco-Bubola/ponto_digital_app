import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../services/device_service.dart';
import '../../utils/constants.dart';
import '../../theme.dart';
import '../../services/session_service.dart';
import '../../widgets/modern_record_card.dart';
import '../../services/notification_service.dart';
import '../../services/push_service.dart';

class TimecardScreen extends StatefulWidget {
  const TimecardScreen({super.key});

  @override
  State<TimecardScreen> createState() => _TimecardScreenState();
}

class _TimecardScreenState extends State<TimecardScreen> {
  TimeRecordType? _currentAction;
  bool _isRecording = false;
  bool _deviceAuthLimitReached = false;
  String _currentTime = '';
  String _currentLocation = 'Carregando localização...';
  String? _debugDeviceId;
  // Estado local para notificação de jornada
  DateTime? _localShiftStart;
  Duration _localPauseAccumulated = Duration.zero;
  DateTime? _localOngoingPauseStart;
  // Dados reais do usuário (fallbacks)
  String _lastRecordTitle = 'Nenhum registro';
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
    // obter deviceId para debug
    DeviceService.getDeviceId().then((id) {
      if (mounted) setState(() => _debugDeviceId = id);
    });
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
  final uri = Uri.parse('${AppConstants.apiBase}/api/time-records');
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
              final entry = first['type'] ?? first['entry'] ?? '—';
              final timeRaw = first['timestamp'] ?? first['createdAt'] ?? '';
              try {
                DateTime.parse(timeRaw.toString()).toLocal();
              } catch (_) {}
              _lastRecordTitle = entry.toString();
              _lastRecordStatus = first['overallStatus'] ?? (first['confirmed'] == true ? 'Confirmado' : _lastRecordStatus);
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
        final entry = r['entry'] ?? '--:--';
          if (mounted) {
          setState(() {
          _lastRecordTitle = 'Entrada - $entry';
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

  // Retorna o texto do badge de entrada (a partir da 2ª entrada)
  String? _entradaBadgeText() {
    final stats = _todayStats();
    final entradaCount = stats['entradaCount'] as int;
    const int maxPerDay = 8;
    if (entradaCount < 2) return null;
    final n = entradaCount.clamp(2, maxPerDay);
    // Formatar sufixo ordinal simples (2ª, 3ª...)
    return '$nª Entrada';
  }

  Future<void> _recordTimecard(TimeRecordType type) async {
    // Se já sabemos que o limite de dispositivos foi atingido, mostrar diálogo e abortar
    if (_deviceAuthLimitReached) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Dispositivo não autorizado'),
            content: const Text('Este dispositivo não pode ser autorizado porque o limite de dispositivos foi atingido. Remova dispositivos antigos pelo portal ou contate o suporte.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Fechar')),
            ],
          ),
        );
      }
      return;
    }

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
  final uri = Uri.parse('${AppConstants.apiBase}/api/time-records');
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
        if (body.contains('Dispositivo não autorizado') || body.contains('ID do dispositivo necessário') || body.toLowerCase().contains('device')) {
          final deviceId = await DeviceService.getDeviceId();
          final authUri = Uri.parse('${AppConstants.apiBase}/api/users/devices');
          final authResp = await http.post(
            authUri,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token'
            },
            body: json.encode({ 'deviceId': deviceId, 'deviceName': 'FlutterApp' })
          );

          // Se a autorização falhou devido a limite de dispositivos, propagamos uma mensagem clara
          if (authResp.statusCode == 400) {
            // Limite de dispositivos atingido — informar o usuário e impedir novas tentativas
            String msg = authResp.body;
            try {
              final parsed = json.decode(authResp.body);
              msg = (parsed['error'] ?? parsed['message'] ?? parsed['detail'] ?? parsed).toString();
            } catch (_) {}
            // Marcar flag para não tentar autorizar novamente nesta sessão
            if (mounted) setState(() => _deviceAuthLimitReached = true);
            // Mostrar diálogo informativo
            if (mounted) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Limite de dispositivos atingido'),
                  content: Text('Não foi possível autorizar este dispositivo: $msg\n\nRemova dispositivos antigos pelo portal ou contate o suporte para liberar mais dispositivos.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Fechar')),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        // abrir instrução de suporte — aqui apenas informa
                      },
                      child: const Text('Suporte'),
                    ),
                  ],
                ),
              );
            }
            // Parar o fluxo de autorização
            return;
          }

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

      Map<String, dynamic>? parsedBody;
      try {
        parsedBody = json.decode(resp.body) as Map<String, dynamic>?;
      } catch (_) {
        parsedBody = null;
      }
      DateTime? serverTimestamp;
      if (parsedBody != null) {
        final tsRaw = parsedBody['timestamp'] ?? parsedBody['createdAt'] ?? parsedBody['time'] ?? parsedBody['recordedAt'];
        if (tsRaw != null) {
          try {
            serverTimestamp = DateTime.parse(tsRaw.toString()).toLocal();
          } catch (_) {
            serverTimestamp = null;
          }
        }
      }

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
          _lastRecordStatus = 'Confirmado';
        });
        // Atualizar notificação persistente/central
        try {
          final svc = await NotificationService.getInstance();
          final text = _buildNotificationTextForType(type);
          // adicionar registro no centro de notificações também
          await svc.addLocalFromPayload(title: _getTypeDisplayName(type), body: text);
          // atualizar notificação persistente (usando id 1000)
            // Integrar com a notificação de jornada persistente
            if (type == TimeRecordType.entrada) {
              // iniciar jornada local e notificação (prefer server timestamp)
              _localShiftStart = serverTimestamp ?? DateTime.now();
              _localPauseAccumulated = Duration.zero;
              _localOngoingPauseStart = null;
              await PushService.startShiftNotification(start: _localShiftStart!, pauseTotal: _localPauseAccumulated);
            } else if (type == TimeRecordType.pausa) {
              // iniciar pausa local e atualizar notificação com ongoingPauseStart (prefer server timestamp)
              _localOngoingPauseStart = serverTimestamp ?? DateTime.now();
              await PushService.startShiftNotification(start: _localShiftStart ?? (serverTimestamp ?? DateTime.now()), pauseTotal: _localPauseAccumulated, ongoingPauseStart: _localOngoingPauseStart);
            } else if (type == TimeRecordType.retorno) {
              // acumular pausa e continuar - se houver serverTimestamp, use ele para calcular a pausa
              if (_localOngoingPauseStart != null) {
                final nowOrServer = serverTimestamp ?? DateTime.now();
                try {
                  final delta = nowOrServer.difference(_localOngoingPauseStart!);
                  if (delta.isNegative == false) {
                    _localPauseAccumulated += delta;
                  }
                } catch (_) {}
                _localOngoingPauseStart = null;
              }
              if (_localShiftStart != null) {
                await PushService.startShiftNotification(start: _localShiftStart!, pauseTotal: _localPauseAccumulated);
              }
            } else if (type == TimeRecordType.saida) {
              // encerrar jornada e remover notificação
              _localOngoingPauseStart = null;
              _localShiftStart = null;
              _localPauseAccumulated = Duration.zero;
              await PushService.stopShiftNotification();
              // além disso, cancelar notificações por id 1000
              await PushService.cancelNotification(1000);
            }
        } catch (_) {}
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

  String _buildNotificationTextForType(TimeRecordType type) {
    final now = DateTime.now();
    switch (type) {
      case TimeRecordType.entrada:
        return 'Trabalhando desde ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      case TimeRecordType.pausa:
        return 'Em pausa desde ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      case TimeRecordType.retorno:
        return 'Retornou ao trabalho às ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      case TimeRecordType.saida:
        return 'Ponto finalizado às ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
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
    final theme = Theme.of(context);
    switch (type) {
      case TimeRecordType.entrada:
        return theme.successColor;
      case TimeRecordType.pausa:
        return theme.warningColor;
      case TimeRecordType.retorno:
        return theme.colorScheme.primary;
      case TimeRecordType.saida:
        return theme.colorScheme.secondary;
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

  // Estatísticas rápidas do dia: contagens e último tipo
  Map<String, dynamic> _todayStats() {
    final todayRecords = _recordsToday();

    // helper to canonicalize type strings into our set: entrada, pausa, retorno, saida
    String canonicalType(String raw) {
      final s = raw.toLowerCase().trim();
      if (s.contains('entrada') || s == 'entry' || s == 'in') return 'entrada';
      if (s.contains('pausa') || s.contains('pause') || s == 'break') return 'pausa';
      if (s.contains('retorno') || s.contains('return') || s == 'ret') return 'retorno';
      if (s.contains('saida') || s.contains('saída') || s.contains('exit') || s.contains('out')) return 'saida';
      return s;
    }

    int entradaCount = 0;
    int pausaCount = 0;
    int retornoCount = 0;
    int saidaCount = 0;
    String? lastType;

    DateTime? latest;
    Map<String, dynamic>? latestRecord;

    for (final r in todayRecords) {
  final rawType = (r['type'] ?? r['entry'] ?? r['event'] ?? '').toString();
  final c = canonicalType(rawType);
      if (c == 'entrada') entradaCount++;
      if (c == 'pausa') pausaCount++;
      if (c == 'retorno') retornoCount++;
      if (c == 'saida') saidaCount++;

      // try parse timestamp
      final rawTs = r['timestamp'] ?? r['createdAt'] ?? r['time'] ?? '';
      try {
        final dt = DateTime.parse(rawTs.toString()).toLocal();
        if (latest == null || dt.isAfter(latest)) {
          latest = dt;
          latestRecord = r;
        }
      } catch (_) {
        // ignore parse errors
      }
    }

    if (latestRecord != null) {
      final rawType = (latestRecord['type'] ?? latestRecord['entry'] ?? latestRecord['event'] ?? '').toString();
      lastType = canonicalType(rawType);
    } else if (todayRecords.isNotEmpty) {
      // fallback: take last element as before
      final last = todayRecords.last;
      final t = (last['type'] ?? last['entry'] ?? last['event'] ?? '').toString();
      lastType = canonicalType(t);
    }

    return {
      'lastType': lastType,
      'entradaCount': entradaCount,
      'pausaCount': pausaCount,
      'retornoCount': retornoCount,
      'saidaCount': saidaCount,
      'records': todayRecords,
    };
  }

  bool _isButtonEnabled(TimeRecordType type) {
    // Regras permitindo múltiplos ciclos e reinício de jornada após saída
    final stats = _todayStats();
    final lastType = stats['lastType'] as String?;
    final entradaCount = stats['entradaCount'] as int;
    final pausaCount = stats['pausaCount'] as int;
    final retornoCount = stats['retornoCount'] as int;
    final saidaCount = stats['saidaCount'] as int;

    const int maxPerDay = 8; // máximo de entradas/pausas/retornos/saídas por dia

    if (_isRecording) return false;

    switch (type) {
      case TimeRecordType.entrada:
        // Só permite nova entrada se não estiver em uma jornada aberta (último não seja 'entrada'/'retorno'/'pausa')
        // ou se a última jornada foi finalizada por 'saida'. Limite máximo de entradas por dia.
        if (entradaCount >= maxPerDay) return false;
        if (lastType == null) return true;
        return lastType == 'saida';
      case TimeRecordType.pausa:
        // Pausa só se houver uma jornada aberta (entradaCount > saidaCount) e o último não for 'pausa'
        if (pausaCount >= maxPerDay) return false;
        final openJornadas = entradaCount - saidaCount;
        if (openJornadas <= 0) return false;
        if (lastType == 'pausa') return false; // evitar pausar duas vezes seguidas
        return lastType == 'entrada' || lastType == 'retorno';
      case TimeRecordType.retorno:
        // Retorno só se a última ação foi 'pausa'
        if (retornoCount >= maxPerDay) return false;
        return lastType == 'pausa';
      case TimeRecordType.saida:
        // Saída se há uma jornada aberta (entradaCount > saidaCount) e último não é 'saida'
        if (saidaCount >= maxPerDay) return false;
        final open = entradaCount - saidaCount;
        if (open <= 0) return false;
        return lastType != 'saida';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.08),
              theme.scaffoldBackgroundColor,
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
                      color: theme.errorColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_recordsError!, style: TextStyle(color: theme.errorColor)),
                  ),
                // ...existing code...
                
                // Header moderno (título à esquerda, horário atual à direita na mesma linha)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                                Icons.fingerprint_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Registro de Ponto',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _getFormattedDate(),
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (_entradaBadgeText() != null) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.onPrimary.withValues(alpha: 0.14),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _entradaBadgeText()!,
                                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Horário atual centralizado abaixo
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onPrimary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.colorScheme.onPrimary.withValues(alpha: 0.18)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Horário Atual',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentTime,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Debug: mostrar deviceId (apenas para testes locais)
                if (_debugDeviceId != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'deviceId: ${_debugDeviceId!}',
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                      textAlign: TextAlign.left,
                    ),
                  ),

                // removido card compacto duplicado (usaremos os mesmos cards do histórico abaixo dos botões)
                
                // Status de localização moderno
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
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
                          color: theme.successColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          color: theme.successColor,
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
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.check_circle_rounded,
                        color: theme.successColor,
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
                          theme.warningColor.withValues(alpha: 0.1),
                          theme.cardColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.warningColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Registrando ${_getTypeDisplayName(_currentAction!)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Validando identidade e localização...',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Selecione o tipo de registro',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                
                
                // Botões de ação modernos em linha única com validações de fluxo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: TimeRecordType.values
                      .where((type) => _isButtonEnabled(type))
                      .map((type) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Tooltip(
                                message: _getTypeDisplayName(type),
                                child: _ModernTimecardButton(
                                  type: type,
                                  emoji: _getTypeEmoji(type),
                                  icon: _getTypeIcon(type),
                                  label: _getTypeDisplayName(type),
                                  color: _getTypeColor(type),
                                  isEnabled: true,
                                  onPressed: () => _recordTimecard(type),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),

                // ===== Últimos Registros (novo layout — igual ao History) =====
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Últimos Registros',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                if (_isLoadingRecords)
                  SizedBox(
                    width: double.infinity,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary)),
                      ),
                    ),
                  )
                else if (_records.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: theme.colorScheme.onSurface.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0,2)),
                      ],
                    ),
                    child: Text(
                      'Nenhum registro recente.',
                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.75)),
                    ),
                  )
                else
                  Column(
                    children: _records.take(5).map((r) {
                      final rawTs = r['timestamp'] ?? r['createdAt'] ?? '';
                      String time = '--:--';
                      String date = '';
                      DateTime? dt;
                      try {
                        dt = DateTime.parse(rawTs.toString()).toLocal();
                        time = DateFormat('HH:mm', 'pt_BR').format(dt);
                        date = DateFormat('dd/MM/yyyy', 'pt_BR').format(dt);
                      } catch (_) {}

                      final typeStr = (r['type'] ?? r['entry'] ?? '').toString();
                      final status = (r['overallStatus'] ?? r['confirmed'] ?? r['status'] ?? '').toString();
                      final location = (r['location'] ?? r['place'] ?? r['address'] ?? '').toString();
                      final total = (r['total'] ?? r['duration'] ?? r['workedDuration'] ?? '').toString();

                      // calcular ocorrência (quantas vezes esse tipo já ocorreu hoje, incluindo este)
                      int occurrence = 1;
                      try {
                        final today = DateTime.now();
                        final sameDay = _records.where((rr) {
                          final ts2 = rr['timestamp'] ?? rr['createdAt'];
                          if (ts2 == null) return false;
                          try {
                            final dt2 = DateTime.parse(ts2.toString()).toLocal();
                            return dt2.year == today.year && dt2.month == today.month && dt2.day == today.day;
                          } catch (_) {
                            return false;
                          }
                        }).toList();

                        final lowerType = typeStr.toLowerCase();
                        occurrence = sameDay.where((rr) {
                          final t = (rr['type'] ?? rr['entry'] ?? '').toString().toLowerCase();
                          return t.contains(lowerType) || lowerType.contains(t);
                        }).toList().indexWhere((map) => map == r) + 1;
                        if (occurrence <= 0) occurrence = 1;
                      } catch (_) {
                        occurrence = 1;
                      }

                      return ModernRecordCard(
                        date: date,
                        type: typeStr,
                        time: time,
                        location: location.isNotEmpty ? location : date,
                        status: status,
                        total: total,
                        occurrence: occurrence,
                      );
                    }).toList(),
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
                colors: [Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.surfaceContainerHighest],
              ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.18),
                  spreadRadius: 0.5,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(height: 4),
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 22,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

