import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/modern_record_card.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/session_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime? _selectedDate = DateTime.now();
  List<TimeRecordItem> _records = [];
  bool _isLoading = false;
  String? _error;
  // Quando null => mostrar todos os registros (sem filtro de data)

  @override
  void initState() {
    super.initState();
    // Carregar registros da data atual
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await SessionService.getToken();
        Uri uri;
        if (_selectedDate == null) {
          uri = Uri.parse('${AppConstants.apiBase}/api/time-records');
        } else {
          // Backend expects a startDate and endDate in ISO format to filter by range.
          final start = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 0, 0, 0);
          final end = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 23, 59, 59, 999);
          final startIso = start.toIso8601String();
          final endIso = end.toIso8601String();
          uri = Uri.parse('${AppConstants.apiBase}/api/time-records?startDate=$startIso&endDate=$endIso');
        }
      final resp = await http.get(uri, headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      });

        if (resp.statusCode == 200) {
          final bodyRaw = json.decode(resp.body);
          List<dynamic> recs = [];
          // backend pode retornar lista direta ou objeto com chaves diferentes
          if (bodyRaw is List) {
            recs = bodyRaw;
          } else if (bodyRaw is Map<String, dynamic>) {
            recs = (bodyRaw['records'] as List<dynamic>?) ?? (bodyRaw['data'] as List<dynamic>?) ?? (bodyRaw['items'] as List<dynamic>?) ?? [];
          }
        // se a resposta foi OK mas não houver registros, avisar o usuário
        if (recs.isEmpty) {
          if (mounted) {
            // mostra um SnackBar informando que não há registros para a data
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_selectedDate == null ? 'Nenhum registro encontrado.' : 'Nenhum registro encontrado para a data selecionada.')),
              );
            });
          }
        }
        final items = recs.map((r) {
          final map = r as Map<String, dynamic>;
          final ts = map['timestamp'] ?? map['createdAt'];
          DateTime dt;
          try {
            dt = DateTime.parse(ts.toString()).toLocal();
          } catch (_) {
            dt = DateTime.now();
          }
          final typeStr = (map['type'] ?? map['entry'] ?? '').toString().toLowerCase();
          TimeRecordType type = TimeRecordType.entrada;
          if (typeStr.contains('pausa')) {
            type = TimeRecordType.pausa;
          } else if (typeStr.contains('retorno')) {
            type = TimeRecordType.retorno;
          } else if (typeStr.contains('saida') || typeStr.contains('saída')) {
            type = TimeRecordType.saida;
          }

          final statusStr = (map['status'] ?? map['overallStatus'] ?? '').toString().toLowerCase();
          RecordStatus status = RecordStatus.valid;
          if (statusStr.contains('pending') || statusStr.contains('pend')) {
            status = RecordStatus.pendingAdjustment;
          } else if (statusStr.contains('invalid') || statusStr.contains('invál')) {
            status = RecordStatus.invalid;
          }

          return TimeRecordItem(
            type: type,
            timestamp: dt,
            status: status,
            location: (map['location'] ?? map['place'] ?? '—').toString(),
          );
        }).toList();

        if (mounted) {
          setState(() {
            _records = items;
            _isLoading = false;
          });
        }
      } else {
        // fallback to mock on error
        if (mounted) {
              setState(() {
                _records = _generateMockRecords(_selectedDate);
            _isLoading = false;
            _error = 'Erro ao buscar histórico: ${resp.statusCode}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
              _records = _generateMockRecords(_selectedDate);
          _isLoading = false;
          _error = 'Falha de conexão';
        });
      }
    }
  }

  // Nota: chamada ao endpoint `/dates` removida por decisão do produto.
  // Permanece a coleção _availableDates para compatibilidade com o seletor,
  // mas ela ficará vazia e o seletor permitirá todas as datas.

  Future<void> _pickDate(BuildContext context) async {
    final firstDate = DateTime.now().subtract(const Duration(days: 365));
    final lastDate = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      await _loadRecords();
    }
  }

  List<TimeRecordItem> _generateMockRecords([DateTime? forDate]) {
    final d = forDate ?? DateTime.now();
    return [
      TimeRecordItem(
        type: TimeRecordType.entrada,
        timestamp: DateTime(d.year, d.month, d.day, 8, 0),
        status: RecordStatus.valid,
        location: 'Escritório Central',
      ),
      TimeRecordItem(
        type: TimeRecordType.pausa,
        timestamp: DateTime(d.year, d.month, d.day, 12, 0),
        status: RecordStatus.valid,
        location: 'Escritório Central',
      ),
      TimeRecordItem(
        type: TimeRecordType.retorno,
        timestamp: DateTime(d.year, d.month, d.day, 13, 0),
        status: RecordStatus.valid,
        location: 'Escritório Central',
      ),
      TimeRecordItem(
        type: TimeRecordType.saida,
        timestamp: DateTime(d.year, d.month, d.day, 17, 30),
        status: RecordStatus.pendingAdjustment,
        location: 'Escritório Central',
      ),
    ];
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
              theme.colorScheme.secondary.withValues(alpha: 0.08),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header moderno
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(AppColors.secondaryTeal),
                      Color(AppColors.primaryBlue),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Color(AppColors.secondaryTeal).withValues(alpha: 0.28),
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
                            color: theme.colorScheme.onPrimary.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.history_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Histórico de Registros',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Acompanhe seus registros de ponto',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onPrimary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.download_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.info_outline, color: theme.colorScheme.onPrimary),
                                      const SizedBox(width: 8),
                                      const Text('Funcionalidade em desenvolvimento'),
                                    ],
                                  ),
                                  backgroundColor: theme.warningColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Seletor de data moderno
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.onPrimary.withValues(alpha: 0.22),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _pickDate(context),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_month_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Data selecionada',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                            _selectedDate == null
                              ? 'Todas as datas'
                              : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de registros
              if (_error != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(AppColors.errorRed).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Color(AppColors.errorRed)),
                  ),
                ),

              Expanded(
                child: _isLoading
                    ? const LoadingIndicator(
                        message: 'Carregando histórico...',
                      )
                    : _records.isEmpty
                        ? const EmptyState(
                            title: 'Nenhum registro encontrado',
                            message: 'Não há registros de ponto para esta data.',
                            icon: Icons.history_rounded,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _records.length,
                            itemBuilder: (context, index) {
                                final record = _records[index];
                                final date = DateFormat('dd/MM/yyyy', 'pt_BR').format(record.timestamp);
                                final time = DateFormat('HH:mm', 'pt_BR').format(record.timestamp);
                                final typeStr = record.type == TimeRecordType.entrada ? 'Entrada' : record.type == TimeRecordType.pausa ? 'Pausa' : record.type == TimeRecordType.retorno ? 'Retorno' : 'Saída';
                                final statusStr = record.status == RecordStatus.valid ? 'Confirmado' : record.status == RecordStatus.pendingAdjustment ? 'Pendente' : 'Inválido';
                                final total = '';

                                // calcular ocorrência (posição deste tipo na lista do dia)
                                int occurrence = 1;
                                try {
                                  final lowerType = typeStr.toLowerCase();
                                  final same = _records.where((rr) {
                                    return rr.type.toString().toLowerCase().contains(lowerType) || lowerType.contains(rr.type.toString().toLowerCase());
                                  }).toList();
                                  occurrence = same.indexWhere((map) => map == record) + 1;
                                  if (occurrence <= 0) occurrence = 1;
                                } catch (_) {
                                  occurrence = 1;
                                }

                                return ModernRecordCard(
                                  date: date,
                                  type: typeStr,
                                  time: time,
                                  location: record.location,
                                  status: statusStr,
                                  total: total,
                                  occurrence: occurrence,
                                );
                              },
                          ),
              ),

              // Resumo do dia
              if (_records.isNotEmpty) _ModernDaySummary(records: _records),
            ],
          ),
        ),
      ),
    );
  }
}

// ...classe _ModernRecordCard removida: uso substituído por ModernRecordCard compartilhado.

class _ModernDaySummary extends StatelessWidget {
  final List<TimeRecordItem> records;

  const _ModernDaySummary({required this.records});

  String _calculateWorkTime() {
    // Calcular tempo total: (saida - entrada) - pausas
    DateTime? entrada;
    DateTime? saida;
    for (final r in records) {
      if (r.type == TimeRecordType.entrada && entrada == null) entrada = r.timestamp;
      if (r.type == TimeRecordType.saida) saida = r.timestamp;
    }

    if (entrada == null) return '--';
    saida ??= records.map((r) => r.timestamp).reduce((a, b) => a.isAfter(b) ? a : b);

    // soma pausas
    Duration pausaTotal = Duration.zero;
    DateTime? pausaInicio;
    for (final r in records..sort((a, b) => a.timestamp.compareTo(b.timestamp))) {
      if (r.type == TimeRecordType.pausa) {
        pausaInicio = r.timestamp;
      } else if (r.type == TimeRecordType.retorno && pausaInicio != null) {
        pausaTotal += r.timestamp.difference(pausaInicio);
        pausaInicio = null;
      }
    }

    final total = saida.difference(entrada) - pausaTotal;
    if (total.isNegative) return '--';
    final hours = total.inHours;
    final minutes = total.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  String _calculateBreakTime() {
    Duration pausaTotal = Duration.zero;
    DateTime? pausaInicio;
    for (final r in records..sort((a, b) => a.timestamp.compareTo(b.timestamp))) {
      if (r.type == TimeRecordType.pausa) {
        pausaInicio = r.timestamp;
      } else if (r.type == TimeRecordType.retorno && pausaInicio != null) {
        pausaTotal += r.timestamp.difference(pausaInicio);
        pausaInicio = null;
      }
    }
    // se houver pausa aberta até o final do dia, conta até o último registro
    if (pausaInicio != null) {
      final last = records.map((r) => r.timestamp).reduce((a, b) => a.isAfter(b) ? a : b);
      pausaTotal += last.difference(pausaInicio);
    }
    final hours = pausaTotal.inHours;
    final minutes = pausaTotal.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  String _calculateStatus() {
    if (records.isEmpty) return 'Vazio';
    // Se houver algum registro pendente, o status é Pendente
    if (records.any((r) => r.status == RecordStatus.pendingAdjustment)) return 'Pendente';
    // Se houver algum inválido
    if (records.any((r) => r.status == RecordStatus.invalid)) return 'Incorreto';
    return 'Completo';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
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
                Icons.summarize_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Resumo do Dia',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.schedule_rounded,
                  title: 'Tempo Total',
                  value: _calculateWorkTime(),
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.coffee_rounded,
                  title: 'Pausas',
                  value: _calculateBreakTime(),
                  color: theme.warningColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.check_circle_rounded,
                  title: 'Registros',
                  value: '${records.length}',
                  color: theme.successColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.trending_up_rounded,
                  title: 'Status',
                  value: _calculateStatus(),
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color ?? Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


// Modelos auxiliares para a tela de histórico
class TimeRecordItem {
  final TimeRecordType type;
  final DateTime timestamp;
  final RecordStatus status;
  final String location;

  TimeRecordItem({
    required this.type,
    required this.timestamp,
    required this.status,
    required this.location,
  });
}

enum RecordStatus {
  valid,
  pendingAdjustment,
  invalid
}
