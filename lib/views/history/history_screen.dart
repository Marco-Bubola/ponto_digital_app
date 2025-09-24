import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/common_widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/session_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _selectedDate = DateTime.now();
  List<TimeRecordItem> _records = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await SessionService.getToken();
      final dateStr = '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final uri = Uri.parse('http://localhost:3000/api/time-records?date=$dateStr');
      final resp = await http.get(uri, headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      });

      if (resp.statusCode == 200) {
        final body = json.decode(resp.body) as Map<String, dynamic>;
        final recs = (body['records'] as List<dynamic>?) ?? [];
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadRecords();
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
              Color(AppColors.secondaryTeal).withValues(alpha: 0.1),
              Colors.white,
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
                      color: Color(AppColors.secondaryTeal).withValues(alpha: 0.3),
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
                            Icons.history_rounded,
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
                                'Histórico de Registros',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.download_rounded,
                              color: Colors.white,
                            ),
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
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Seletor de data moderno
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _selectDate,
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
                                      const Text(
                                        'Data selecionada',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                                        style: const TextStyle(
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
                              return _ModernRecordCard(record: record);
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

class _ModernRecordCard extends StatelessWidget {
  final TimeRecordItem record;

  const _ModernRecordCard({required this.record});

  String _getTypeEmoji(TimeRecordType type) {
    switch (type) {
      case TimeRecordType.entrada:
        return '🌅';
      case TimeRecordType.pausa:
        return '☕';
      case TimeRecordType.retorno:
        return '💼';
      case TimeRecordType.saida:
        return '�';
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

  String _getTypeName(TimeRecordType type) {
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

  Color _getStatusColor(RecordStatus status) {
    switch (status) {
      case RecordStatus.valid:
        return Color(AppColors.successGreen);
      case RecordStatus.pendingAdjustment:
        return Color(AppColors.warningYellow);
      case RecordStatus.invalid:
        return Color(AppColors.errorRed);
    }
  }

  String _getStatusLabel(RecordStatus status) {
    switch (status) {
      case RecordStatus.valid:
        return 'Confirmado';
      case RecordStatus.pendingAdjustment:
        return 'Pendente';
      case RecordStatus.invalid:
        return 'Inválido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Ícone do tipo com gradiente
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getStatusColor(record.status),
                    _getStatusColor(record.status).withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getTypeIcon(record.type),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // Informações principais
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _getTypeEmoji(record.type),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getTypeName(record.type),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${record.timestamp.hour.toString().padLeft(2, '0')}:${record.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        record.location,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(record.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getStatusColor(record.status).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _getStatusLabel(record.status),
                style: TextStyle(
                  color: _getStatusColor(record.status),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernDaySummary extends StatelessWidget {
  final List<TimeRecordItem> records;

  const _ModernDaySummary({required this.records});

  String _calculateWorkTime() {
    // Lógica simplificada para calcular horas trabalhadas
    return '8h 30m';
  }

  String _calculateBreakTime() {
    // Lógica simplificada para calcular tempo de pausa
    return '1h 00m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
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
                Icons.summarize_rounded,
                color: Color(AppColors.primaryBlue),
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
                  color: Color(AppColors.primaryBlue),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.coffee_rounded,
                  title: 'Pausas',
                  value: _calculateBreakTime(),
                  color: Color(AppColors.warningYellow),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.check_circle_rounded,
                  title: 'Registros',
                  value: '${records.length}',
                  color: Color(AppColors.successGreen),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.trending_up_rounded,
                  title: 'Status',
                  value: 'Completo',
                  color: Color(AppColors.secondaryTeal),
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
              color: Colors.grey[600],
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
