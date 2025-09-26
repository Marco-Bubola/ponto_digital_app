import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
// ignore: unused_import
import 'package:ponto_digital_app/utils/web_download_stub.dart'
  if (dart.library.html) 'package:ponto_digital_app/utils/web_download.dart';

import '../../utils/constants.dart';
import '../../services/session_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'month';
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _records = [];
  DateTime _selectedWeekStart = DateTime.now();

  // summary values
  String _hoursWorked = '0h 00m';
  String _daysWorked = '0';
  String _overtime = '0h 00m';
  String _absences = '0';

  @override
  void initState() {
    super.initState();
    _selectedWeekStart = _getWeekStart(DateTime.now());
    _fetchRecordsForPeriod();
  }

  DateTime _getWeekStart(DateTime dt) => dt.subtract(Duration(days: dt.weekday - 1));

  void _prevWeek() {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.add(const Duration(days: 7));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchRecordsForPeriod,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Header moderno replicando estilo das outras telas
                Container(
                  margin: const EdgeInsets.all(20),
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
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Color(AppColors.primaryBlue).withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Builder(builder: (context) {
                    final colorScheme = Theme.of(context).colorScheme;
                    final onPrimary = colorScheme.onPrimary;
                    return Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              // subtle circle background using withValues
                              color: onPrimary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.arrow_back, color: onPrimary),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            // make the icon background theme-aware and avoid withOpacity deprecation
                            color: onPrimary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.bar_chart_rounded, color: onPrimary, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Relatórios', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: onPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Visão semanal e exportação', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: onPrimary.withValues(alpha: 0.9), fontSize: 13)),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Exportar',
                          icon: Icon(Icons.more_vert, color: onPrimary),
                          onPressed: _showExportOptions,
                        ),
                      ],
                    );
                  }),
                ),
                _buildPeriodCard(context),
              const SizedBox(height: 20),
              Text('Resumo Geral', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _buildSummaryGrid(),
              const SizedBox(height: 20),
              Text('Histórico Detalhado', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _buildRecordsCard(),
              const SizedBox(height: 20),
              _buildFrequencyPlaceholder(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list, color: Color(AppColors.primaryBlue)),
                const SizedBox(width: 8),
                Text('Período', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: _fetchRecordsForPeriod,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Atualizar'),
                )
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _PeriodChip(label: 'Esta Semana', value: 'week', selected: _selectedPeriod == 'week', onSelected: _onPeriodChanged),
                _PeriodChip(label: 'Este Mês', value: 'month', selected: _selectedPeriod == 'month', onSelected: _onPeriodChanged),
                _PeriodChip(label: 'Trimestre', value: 'quarter', selected: _selectedPeriod == 'quarter', onSelected: _onPeriodChanged),
                _PeriodChip(label: 'Personalizado', value: 'custom', selected: _selectedPeriod == 'custom', onSelected: _onPeriodChanged),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return Row(
      children: [
        Expanded(child: _SummaryCard(title: 'Horas Trabalhadas', value: _hoursWorked, icon: Icons.access_time, color: Color(AppColors.primaryBlue), trend: '')),
        const SizedBox(width: 12),
        Expanded(child: _SummaryCard(title: 'Dias Trabalhados', value: _daysWorked, icon: Icons.calendar_today, color: Color(AppColors.successGreen), trend: '')),
        const SizedBox(width: 12),
        Expanded(child: _SummaryCard(title: 'Horas Extras', value: _overtime, icon: Icons.add_circle, color: Color(AppColors.warningYellow), trend: '')),
        const SizedBox(width: 12),
        Expanded(child: _SummaryCard(title: 'Faltas', value: _absences, icon: Icons.cancel, color: Color(AppColors.errorRed), trend: '')),
      ],
    );
  }

  Widget _buildRecordsCard() {
    return Card(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(AppColors.primaryBlue),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Builder(builder: (context) {
              final onPrimary = Theme.of(context).colorScheme.onPrimary;
              return Row(
                children: [
                  Expanded(flex: 2, child: Text('Data', style: TextStyle(color: onPrimary, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Entrada', style: TextStyle(color: onPrimary, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Saída', style: TextStyle(color: onPrimary, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Total', style: TextStyle(color: onPrimary, fontWeight: FontWeight.bold))),
                ],
              );
            }),
          ),
          if (_isLoading) const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())) else _buildRecordsList(),
        ],
      ),
    );
  }

  Widget _buildRecordsList() {
    if (_error != null) return Padding(padding: const EdgeInsets.all(16), child: Text('Erro: $_error'));
    if (_records.isEmpty) return Padding(padding: const EdgeInsets.all(16), child: Center(child: Text('Sem registros para esse período')));

    // group records by date to render daily rows
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final r in _records) {
      DateTime? dt;
      final ts = r['timestamp'] ?? r['createdAt'];
      if (ts != null) {
        try {
          dt = DateTime.parse(ts.toString()).toLocal();
        } catch (_) {
          dt = null;
        }
      }
      final day = dt != null ? DateFormat('yyyy-MM-dd').format(dt) : (r['date'] ?? 'unknown');
      grouped.putIfAbsent(day, () => []).add(r);
    }

    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final dayKey = days[index];
        final items = grouped[dayKey]!;
        // compute first and last timestamps for the day
        DateTime? first;
        DateTime? last;
        for (final r in items) {
          final ts = r['timestamp'] ?? r['createdAt'];
          if (ts == null) continue;
          try {
            final dt = DateTime.parse(ts.toString()).toLocal();
            if (first == null || dt.isBefore(first)) first = dt;
            if (last == null || dt.isAfter(last)) last = dt;
          } catch (_) {}
        }

        final dateStr = first != null ? DateFormat('dd/MM/yyyy').format(first) : dayKey;
        final entryStr = first != null ? DateFormat('HH:mm').format(first) : '--:--';
        final exitStr = last != null ? DateFormat('HH:mm').format(last) : '--:--';
        final total = (first != null && last != null) ? _formatDuration(last.difference(first)) : '--:--';

        return _TimeRecordRow(date: dateStr, entry: entryStr, exit: exitStr, total: total, isOdd: index % 2 == 1);
      },
    );
  }

  Widget _buildFrequencyPlaceholder(BuildContext context) {
    // build weekly data from _records using selected week
    final weekStart = _selectedWeekStart;
    final days = List.generate(7, (i) => DateTime(weekStart.year, weekStart.month, weekStart.day + i));

    // calculate worked minutes per day by grouping timestamps for each day and taking first/last
    final grouped = <String, List<DateTime>>{};
    for (final r in _records) {
      DateTime? dt;
      final ts = r['timestamp'] ?? r['createdAt'];
      if (ts != null) {
        try {
          dt = DateTime.parse(ts.toString()).toLocal();
        } catch (_) {
          dt = null;
        }
      }
      if (dt == null) continue;
      final key = DateFormat('yyyy-MM-dd').format(dt);
      if (!grouped.containsKey(key)) grouped[key] = [];
      grouped[key]!.add(dt);
    }

    final workedByDay = <String, int>{};
    for (final d in days) {
      final key = DateFormat('yyyy-MM-dd').format(d);
      final list = (grouped[key] ?? [])..sort();
      if (list.length >= 2) {
        final minutes = list.last.difference(list.first).inMinutes;
        workedByDay[key] = minutes;
      } else {
        workedByDay[key] = 0;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Frequência Semanal', style: Theme.of(context).textTheme.titleMedium)),
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: _prevWeek),
                Text('${DateFormat('dd/MM').format(_selectedWeekStart)} - ${DateFormat('dd/MM').format(_selectedWeekStart.add(const Duration(days: 6)))}'),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextWeek),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: _WeeklyBarChart(days: days, workedByDay: workedByDay),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Exportar Relatório', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ListTile(leading: Icon(Icons.copy, color: Color(AppColors.primaryBlue)), title: const Text('Copiar CSV (área de transferência)'), onTap: () {
              Navigator.pop(context);
              _exportWeekCsv();
            }),
            ListTile(leading: Icon(Icons.save_alt, color: Color(AppColors.successGreen)), title: const Text('Salvar como arquivo (temporário)'), onTap: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();
              final csv = _buildWeekCsvString();
              final path = await _saveCsvToFile(csv);
              if (path != null) {
                if (!mounted) return;
                messenger.showSnackBar(SnackBar(content: Text('Arquivo salvo: $path')));
              }
            }),
            ListTile(leading: Icon(Icons.share, color: Color(AppColors.secondaryTeal)), title: const Text('Compartilhar'), onTap: () async {
              Navigator.pop(context);
              final csv = _buildWeekCsvString();
              await _shareCsv(csv);
            }),
          ],
        ),
      ),
    );
  }

  String _buildWeekCsvString() {
    final start = _selectedWeekStart;
  final rows = <List<String>>[];
  rows.add(['data', 'entrada', 'saida', 'minutos_trabalhados', 'minutos_hhmm']);

    final grouped = <String, List<DateTime>>{};
    for (final r in _records) {
      DateTime? dt;
      final ts = r['timestamp'] ?? r['createdAt'];
      if (ts != null) {
        try {
          dt = DateTime.parse(ts.toString()).toLocal();
        } catch (_) {
          dt = null;
        }
      }
      if (dt == null) continue;
      final key = DateFormat('yyyy-MM-dd').format(dt);
      grouped.putIfAbsent(key, () => []).add(dt);
    }

    final days = List.generate(7, (i) => start.add(Duration(days: i)));
    for (final d in days) {
      final key = DateFormat('yyyy-MM-dd').format(d);
      final list = (grouped[key] ?? [])..sort();
      if (list.length >= 2) {
        final first = DateFormat('HH:mm').format(list.first);
        final last = DateFormat('HH:mm').format(list.last);
        final minutes = list.last.difference(list.first).inMinutes;
        final hh = '${(minutes ~/ 60).toString()}h ${(minutes % 60).toString().padLeft(2, '0')}m';
        rows.add([DateFormat('yyyy-MM-dd').format(d), first, last, minutes.toString(), hh]);
      } else {
        rows.add([DateFormat('yyyy-MM-dd').format(d), '--:--', '--:--', '0', '0h 00m']);
      }
    }

    final csv = rows.map((r) => r.map((c) => '"${c.replaceAll('"', '""')}"').join(',')).join('\n');
    return csv;
  }

  Future<String?> _saveCsvToFile(String csv) async {
    try {
      final fileName = 'relatorio_semana_${DateFormat('yyyyMMdd').format(_selectedWeekStart)}.csv';
      // Prefer path_provider for a writable temp dir
      Directory dir;
      if (kIsWeb) throw Exception('Salvar arquivo não disponível na Web');
      try {
        dir = await getTemporaryDirectory();
      } catch (_) {
        dir = Directory.systemTemp;
      }
      final f = File('${dir.path}/$fileName');
      await f.writeAsString(csv, flush: true);
      return f.path;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao salvar arquivo: $e')));
      return null;
    }
  }

  Future<void> _shareCsv(String csv) async {
    if (kIsWeb) {
      // fallback: copy to clipboard
      await Clipboard.setData(ClipboardData(text: csv));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV copiado para a área de transferência (web)')));
      return;
    }

    final path = await _saveCsvToFile(csv);
    if (path == null) return;
    try {
  // new API: SharePlus.instance.share
  // fallback: compartilhar texto com o caminho do arquivo (algumas plataformas exigem APIs diferentes)
  await SharePlus.instance.share(ShareParams(text: 'Relatório semanal - arquivo salvo em: $path'));
    } catch (e) {
      // fallback para copiar para clipboard
      await Clipboard.setData(ClipboardData(text: csv));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha ao compartilhar. CSV copiado para a área de transferência.')));
    }
  }

  void _onPeriodChanged(String value) {
    setState(() {
      _selectedPeriod = value;
    });
    _fetchRecordsForPeriod();
  }

  Future<void> _fetchRecordsForPeriod() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = await SessionService.getToken();
      if (token == null) throw Exception('Usuário não autenticado');

      // compute date range
      DateTime now = DateTime.now();
      DateTime start;
      DateTime end = now;
      if (_selectedPeriod == 'week') {
        // use selected week start if present
        start = _selectedWeekStart;
        end = _selectedWeekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      } else if (_selectedPeriod == 'month') {
        start = DateTime(now.year, now.month, 1);
      } else if (_selectedPeriod == 'quarter') {
        int q = ((now.month - 1) ~/ 3);
        start = DateTime(now.year, q * 3 + 1, 1);
      } else {
        start = DateTime(now.year, now.month, 1);
      }

  final uri = Uri.parse('${AppConstants.apiBase}/api/time-records?startDate=${start.toIso8601String()}&endDate=${end.toIso8601String()}');
  final resp = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
      if (resp.statusCode == 200) {
        final body = json.decode(resp.body) as Map<String, dynamic>;
        final recs = (body['records'] as List<dynamic>?) ?? (body['data'] as List<dynamic>?) ?? [];
        _records = recs.map((r) => Map<String, dynamic>.from(r as Map)).toList();
        _computeSummaryFromRecords();
      } else if (resp.statusCode == 401) {
        _error = 'Token de acesso necessário (401)';
      } else {
        _error = 'Erro ao buscar registros: ${resp.statusCode}';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportWeekCsv() async {
    // prepare CSV from current _records filtered by selected week
    final start = _selectedWeekStart;
    final end = _selectedWeekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    final rows = <List<String>>[];
    rows.add(['data', 'entrada', 'saida', 'minutos_trabalhados']);

    // group by date
    final grouped = <String, List<DateTime>>{};
    for (final r in _records) {
      DateTime? dt;
      final ts = r['timestamp'] ?? r['createdAt'];
      if (ts != null) {
        try {
          dt = DateTime.parse(ts.toString()).toLocal();
        } catch (_) {
          dt = null;
        }
      }
      if (dt == null) continue;
      if (dt.isBefore(start) || dt.isAfter(end)) continue;
      final key = DateFormat('yyyy-MM-dd').format(dt);
      grouped.putIfAbsent(key, () => []).add(dt);
    }

    final days = List.generate(7, (i) => start.add(Duration(days: i)));
    for (final d in days) {
      final key = DateFormat('yyyy-MM-dd').format(d);
      final list = (grouped[key] ?? [])..sort();
      if (list.length >= 2) {
        final first = DateFormat('HH:mm').format(list.first);
        final last = DateFormat('HH:mm').format(list.last);
        final minutes = list.last.difference(list.first).inMinutes;
        rows.add([DateFormat('yyyy-MM-dd').format(d), first, last, minutes.toString()]);
      } else {
        rows.add([DateFormat('yyyy-MM-dd').format(d), '--:--', '--:--', '0']);
      }
    }

    final csv = rows.map((r) => r.map((c) => '"${c.replaceAll('"', '""')}"').join(',')).join('\n');
    await Clipboard.setData(ClipboardData(text: csv));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV copiado para a área de transferência')));
  }

  void _computeSummaryFromRecords() {
    Duration totalWorked = Duration.zero;
    final dates = <String, List<DateTime>>{};
    for (final r in _records) {
      DateTime? dt;
      final ts = r['timestamp'] ?? r['createdAt'];
      if (ts != null) {
        try {
          dt = DateTime.parse(ts.toString()).toLocal();
        } catch (_) {
          dt = null;
        }
      }
      if (dt == null) continue;
      final key = DateFormat('yyyy-MM-dd').format(dt);
      dates.putIfAbsent(key, () => []).add(dt);
    }

    for (final entry in dates.entries) {
      final list = entry.value..sort();
      if (list.length >= 2) totalWorked += list.last.difference(list.first);
    }

    final daysWorked = dates.keys.length;

    Duration overtime = Duration.zero;
    for (final entry in dates.entries) {
      final list = entry.value..sort();
      if (list.length >= 2) {
        final worked = list.last.difference(list.first);
        if (worked > const Duration(hours: 8)) overtime += (worked - const Duration(hours: 8));
      }
    }

    final absences = 0;

    _hoursWorked = _formatDuration(totalWorked);
    _daysWorked = daysWorked.toString();
    _overtime = _formatDuration(overtime);
    _absences = absences.toString();
  }

  String _formatDuration(Duration d) {
    return '${d.inHours}h ${d.inMinutes.remainder(60).toString().padLeft(2, '0')}m';
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final ValueChanged<String> onSelected;

  const _PeriodChip({required this.label, required this.value, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) {
        if (v) onSelected(value);
      },
      selectedColor: Color(AppColors.primaryBlue).withValues(alpha: 31),
      checkmarkColor: Color(AppColors.primaryBlue),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;

  const _SummaryCard({required this.title, required this.value, required this.icon, required this.color, required this.trend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
            child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ]),
          ),
          if (trend.isNotEmpty) Text(trend, style: TextStyle(color: Colors.green))
        ],
      ),
    );
  }
}

class _TimeRecordRow extends StatelessWidget {
  final String date;
  final String entry;
  final String exit;
  final String total;
  final bool isOdd;

  const _TimeRecordRow({required this.date, required this.entry, required this.exit, required this.total, required this.isOdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
  final bg = isOdd ? theme.colorScheme.surfaceContainerHighest : theme.cardColor;
    final txtColor = theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(children: [
        Expanded(flex: 2, child: Text(date, style: TextStyle(color: txtColor))),
        Expanded(child: Text(entry, style: TextStyle(color: txtColor))),
        Expanded(child: Text(exit, style: TextStyle(color: txtColor))),
        Expanded(child: Text(total, style: TextStyle(color: txtColor))),
      ]),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final List<DateTime> days;
  final Map<String, int> workedByDay; // stores minutes worked per day

  const _WeeklyBarChart({required this.days, required this.workedByDay});

  @override
  Widget build(BuildContext context) {
    final spots = <BarChartGroupData>[];
    int maxVal = 1;
    final colorScheme = Theme.of(context).colorScheme;
    for (int i = 0; i < days.length; i++) {
      final key = DateFormat('yyyy-MM-dd').format(days[i]);
      final val = workedByDay[key] ?? 0; // minutes
      if (val > maxVal) maxVal = val;
      spots.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(toY: val.toDouble(), color: colorScheme.primary, width: 18, borderRadius: BorderRadius.circular(4)),
          ],
          showingTooltipIndicators: val > 0 ? [0] : [],
        ),
      );
    }
  double maxY = maxVal.toDouble() * 1.2;
  if (maxY < 10.0) maxY = 10.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barGroups: spots,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final minutes = rod.toY.toInt();
              final hours = minutes ~/ 60;
              final mins = minutes % 60;
              final label = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
              return BarTooltipItem('$label\n', TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold));
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) {
            // show labels in hours where appropriate
            // convert value (minutes) to hh:mm labels at sensible intervals
            final intVal = value.toInt();
            if (intVal <= 0) return Text('', style: const TextStyle(fontSize: 10));
            if (intVal % 60 == 0) {
              final h = (intVal ~/ 60).toString();
              return Text('${h}h', style: const TextStyle(fontSize: 12));
            }
            // show minutes label for small values
            if (intVal < 60) return Text('${intVal}m', style: const TextStyle(fontSize: 10));
            return Text('', style: const TextStyle(fontSize: 10));
          })),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (index, meta) {
                final idx = index.toInt();
                if (idx < 0 || idx >= days.length) return const SizedBox();
                final label = DateFormat('E').format(days[idx]);
                return Padding(padding: const EdgeInsets.only(top: 6), child: Text(label, style: const TextStyle(fontSize: 12)));
              },
            ),
          ),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
