import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import '../timecard/timecard_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import '../adjustments/adjustments_screen.dart';
import '../reports/reports_screen.dart';
import '../../utils/constants.dart';
import '../../theme.dart';
import '../../services/session_service.dart';
import '../../services/device_service.dart';
import '../../widgets/modern_record_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardContent(onNavigate: (int index) => setState(() => _currentIndex = index)),
      const TimecardScreen(),
      const HistoryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time_outlined), activeIcon: Icon(Icons.access_time), label: 'Ponto'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'Histórico'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Configurações'),
        ],
      ),
    );
  }
}

class DashboardContent extends StatefulWidget {
  final void Function(int index)? onNavigate;

  const DashboardContent({super.key, this.onNavigate});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  String userName = 'Usuário';
  String companyName = '';

  String entryTime = '--:--';
  String exitTime = '--:--';
  String entrySubtitle = 'Aguardando';
  String exitSubtitle = 'Aguardando';

  String weekHours = '0h 00m';
  String daysPresent = '0/0';
  String overtime = '0h 00m';
  String balance = '+0h 00m';

  List<Map<String, dynamic>> recentRecords = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final user = await SessionService.getUser();
      if (user != null) {
        setState(() {
          userName = user['name'] ?? userName;
          companyName = (user['company'] != null && user['company']['name'] != null) ? user['company']['name'] : '';
        });
      }
    } catch (_) {}

    await _fetchTimeRecords();
  }

  Future<void> _fetchTimeRecords() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
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
            final dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');
            final timeFmt = DateFormat('HH:mm', 'pt_BR');

            final parsed = recs.map((r) {
              final map = Map<String, dynamic>.from(r as Map);
              final ts = map['timestamp'] ?? map['createdAt'];
              DateTime? dt;
              if (ts != null) {
                try {
                  dt = DateTime.parse(ts.toString()).toLocal();
                } catch (_) {
                  dt = null;
                }
              }
              map['_ts'] = dt;
              return map;
            }).toList();

            parsed.sort((a, b) {
              final aTs = a['_ts'] as DateTime?;
              final bTs = b['_ts'] as DateTime?;
              if (aTs == null && bTs == null) return 0;
              if (aTs == null) return 1;
              if (bTs == null) return -1;
              return bTs.compareTo(aTs);
            });

            // Hoje
            final today = DateTime.now();
            bool sameDay(DateTime d) => d.year == today.year && d.month == today.month && d.day == today.day;
            final todayRecords = parsed.where((m) => (m['_ts'] as DateTime?) != null && sameDay(m['_ts'] as DateTime)).toList();

            DateTime? entradaDt;
            DateTime? saidaDt;
            for (final r in todayRecords) {
              final typeStr = (r['type'] ?? r['action'] ?? '').toString().toLowerCase();
              final ts = r['_ts'] as DateTime?;
              if (ts == null) continue;
              if (entradaDt == null && (typeStr.contains('entrada') || typeStr.contains('entry'))) entradaDt = ts;
              if (typeStr.contains('saida') || typeStr.contains('saída') || typeStr.contains('exit')) {
                if (saidaDt == null || ts.isAfter(saidaDt)) saidaDt = ts;
              }
            }

            String fmtTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
            if (entradaDt != null) entryTime = fmtTime(entradaDt);
            if (saidaDt != null) exitTime = fmtTime(saidaDt);

            if (todayRecords.isNotEmpty) {
              final last = todayRecords.first;
              entrySubtitle = last['location'] is Map ? (last['location']['name'] ?? entrySubtitle) : (last['location']?.toString() ?? entrySubtitle);
            }

            // Semana: agrupar registros por dia e somar pares entrada->saída para cada dia
            final now = DateTime.now();
            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
            final endOfWeek = startOfWeek.add(const Duration(days: 6));
            final weekRecords = parsed.where((m) {
              final dt = m['_ts'] as DateTime?;
              if (dt == null) return false;
              return !(dt.isBefore(startOfWeek) || dt.isAfter(endOfWeek));
            }).toList();

            // Agrupa por dia (yyyy-MM-dd) os eventos da semana
            final Map<String, List<Map<String, dynamic>>> byDay = {};
            for (final r in weekRecords) {
              final dt = r['_ts'] as DateTime?;
              if (dt == null) continue;
              final key = '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
              byDay.putIfAbsent(key, () => []).add({'type': (r['type'] ?? r['action'] ?? '').toString().toLowerCase(), 'ts': dt, 'raw': r});
            }

            Duration totalWeek = Duration.zero;
            final presentDays = <String>{};

            for (final entry in byDay.entries) {
              final dayKey = entry.key;
              final events = entry.value;
              events.sort((a, b) => (a['ts'] as DateTime).compareTo(b['ts'] as DateTime));

              Duration dayTotal = Duration.zero;
              DateTime? lastEntry;

              for (final ev in events) {
                final typeStr = (ev['type'] ?? '').toString();
                final ts = ev['ts'] as DateTime?;
                if (ts == null) continue;

                if (typeStr.contains('entrada') || typeStr.contains('entry') || typeStr.contains('in')) {
                  lastEntry = ts;
                } else if (typeStr.contains('saida') || typeStr.contains('saída') || typeStr.contains('exit') || typeStr.contains('out')) {
                  if (lastEntry != null) {
                    final diffDur = ts.difference(lastEntry);
                    if (!diffDur.isNegative) dayTotal += diffDur;
                    lastEntry = null;
                  }
                }
              }

              // Se o dia tiver total calculado (ex: campo 'total' no registro resumo), tente usar como fallback
              if (dayTotal == Duration.zero) {
                for (final ev in events) {
                  final raw = ev['raw'] as Map<String, dynamic>?;
                  if (raw == null) continue;
                  if (raw['total'] != null && raw['total'].toString().isNotEmpty) {
                    try {
                      final s = raw['total'].toString();
                      final hMatch = RegExp(r"(\d+)h").firstMatch(s);
                      final mMatch = RegExp(r"(\d+)m").firstMatch(s);
                      final h = hMatch != null ? int.parse(hMatch.group(1)!) : 0;
                      final mm = mMatch != null ? int.parse(mMatch.group(1)!) : 0;
                      dayTotal = Duration(hours: h, minutes: mm);
                      break;
                    } catch (_) {}
                  }
                }
              }

              if (dayTotal > Duration.zero) {
                totalWeek += dayTotal;
                presentDays.add(dayKey);
              }
            }

            final expectedPerDay = Duration(hours: 8);
            final expectedTotal = expectedPerDay * presentDays.length;
            final diff = totalWeek - expectedTotal;

            String fmtDur(Duration d) {
              final sign = d.isNegative ? '-' : '';
              final ad = d.abs();
              final h = ad.inHours;
              final m = ad.inMinutes.remainder(60);
              return '$sign${h}h ${m}m';
            }

            weekHours = fmtDur(totalWeek);
            daysPresent = '${presentDays.length}/7';
            // debug: log computed week totals
            // ignore: avoid_print
            print('[DASHBOARD DEBUG] totalWeek=${totalWeek.inMinutes}min presentDays=${presentDays.length}');
            if (diff.isNegative) {
              overtime = '0h 00m';
              balance = fmtDur(diff);
            } else {
              overtime = fmtDur(diff);
              balance = '+$overtime';
            }

            recentRecords = parsed.take(5).map<Map<String, dynamic>>((r) {
              String date = '—';
              String entry = '--:--';
              String exit = '--:--';
              String total = '0h 00m';
              String displayTime = '--:--';

              final dt = r['_ts'] as DateTime?;
              if (dt != null) date = dateFmt.format(dt);

              if (r['entryTime'] != null) {
                try {
                  final dte = DateTime.parse(r['entryTime'].toString()).toLocal();
                  entry = timeFmt.format(dte);
                } catch (_) {
                  entry = r['entryTime'].toString();
                }
              }
              if (r['exitTime'] != null) {
                try {
                  final dte = DateTime.parse(r['exitTime'].toString()).toLocal();
                  exit = timeFmt.format(dte);
                } catch (_) {
                  exit = r['exitTime'].toString();
                }
              }
              if (entry != '--:--') {
                displayTime = entry;
              } else if (dt != null) {
                displayTime = timeFmt.format(dt);
              }
              if (r['total'] != null) total = r['total'].toString();

              return {
                'date': date,
                'entry': entry,
                'exit': exit,
                'total': total,
                'type': r['type'] ?? r['action'] ?? '',
                'location': r['location'],
                'status': r['status'] ?? 'valid',
                'timestamp': r['_ts'],
                'displayTime': displayTime,
              };
            }).toList();
          });
        }
      } else {
        setState(() {
          _error = 'Erro ao buscar registros: ${resp.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Falha de conexão';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 220,
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _HeaderBackgroundPainter(theme: theme))),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(AppColors.primaryBlue).withValues(alpha: 0.92),
                          Color(AppColors.primaryBlue).withValues(alpha: 0.7),
                          Color(AppColors.secondaryTeal).withValues(alpha: 0.12),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                            padding: const EdgeInsets.all(10.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(colors: [Colors.white, Colors.white.withValues(alpha: 0.85)]),
                                  ),
                                  child: const CircleAvatar(radius: 26, backgroundColor: Colors.white, child: Icon(Icons.person, size: 30, color: Colors.black87)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Olá, $userName 👋', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                                      const SizedBox(height: 2),
                                      Text(companyName.isNotEmpty ? companyName : 'Ponto Digital', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.95), fontSize: 13)),
                                      const SizedBox(height: 2),
                                      Text('Hoje é ${_getFormattedDate()}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.95), fontSize: 13)),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
                                  child: IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white), onPressed: () {}),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 88,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _ModernStatusCard(
                                      title: 'Entrada',
                                      time: entryTime,
                                      subtitle: entrySubtitle == 'Aguardando' || entrySubtitle.isEmpty ? '' : entrySubtitle,
                                      icon: Icons.login_rounded,
                                      color: theme.colorScheme.tertiary,
                                      isPositive: entryTime != '--:--',
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Container(width: 1, margin: const EdgeInsets.symmetric(vertical: 6), color: theme.colorScheme.onSurface.withValues(alpha: 0.06)),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: _ModernStatusCard(
                                      title: 'Saída',
                                      time: exitTime,
                                      subtitle: exitSubtitle == 'Aguardando' || exitSubtitle.isEmpty ? '' : exitSubtitle,
                                      icon: Icons.logout_rounded,
                                      color: theme.colorScheme.secondary,
                                      isPositive: exitTime != '--:--',
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
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: Offset.zero,
            child: Container(
              decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: RefreshIndicator(
                  onRefresh: _fetchTimeRecords,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        if (_error != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: theme.colorScheme.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.22))),
                            child: Row(children: [Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20), const SizedBox(width: 8), Expanded(child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))), IconButton(onPressed: () => setState(() => _error = null), icon: Icon(Icons.close, color: theme.colorScheme.error, size: 18))]),
                          ),
                        Row(children: [Icon(Icons.flash_on_rounded, color: Theme.of(context).colorScheme.primary, size: 28), const SizedBox(width: 8), Text('Ações Rápidas', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))]),
                        const SizedBox(height: 16),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Expanded(child: SizedBox(height: 92, child: _ModernActionCard(title: 'Registrar\nPonto', icon: Icons.fingerprint_rounded, gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)]), onTap: () { if (widget.onNavigate != null) { widget.onNavigate!(1); } else { Navigator.push(context, MaterialPageRoute(builder: (c) => const TimecardScreen())); } }))),
                          const SizedBox(width: 12),
                          Expanded(child: SizedBox(height: 92, child: _ModernActionCard(title: 'Espelho\nDigital', icon: Icons.receipt_long_rounded, gradient: LinearGradient(colors: [theme.colorScheme.secondary, theme.colorScheme.secondary.withValues(alpha: 0.8)]), onTap: () { if (widget.onNavigate != null) { widget.onNavigate!(2); } else { Navigator.push(context, MaterialPageRoute(builder: (c) => const HistoryScreen())); } }))),
                          const SizedBox(width: 12),
                          Expanded(child: SizedBox(height: 92, child: _ModernActionCard(title: 'Solicitações', icon: Icons.edit_note_rounded, gradient: LinearGradient(colors: [theme.colorScheme.tertiary, theme.colorScheme.tertiary.withValues(alpha: 0.8)]), onTap: () { Navigator.push(context, MaterialPageRoute(builder: (c) => const AdjustmentsScreen())); }))),
                          const SizedBox(width: 12),
                          Expanded(child: SizedBox(height: 92, child: _ModernActionCard(title: 'Relatórios', icon: Icons.analytics_rounded, gradient: LinearGradient(colors: [theme.colorScheme.secondaryContainer, theme.colorScheme.secondaryContainer.withValues(alpha: 0.8)]), onTap: () { Navigator.push(context, MaterialPageRoute(builder: (c) => const ReportsScreen())); }))),
                        ]),
                        const SizedBox(height: 32),
                        Row(children: [Icon(Icons.bar_chart_rounded, color: Theme.of(context).colorScheme.primary, size: 28), const SizedBox(width: 8), Text('Esta Semana', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))]),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.08), spreadRadius: 1, blurRadius: 10, offset: const Offset(0, 2))]),
                          child: LayoutBuilder(builder: (context, constraints) {
                            final spacing = 12.0;
                            return Row(children: [
                              Expanded(child: _WeekStatCard(title: 'Horas\nTrabalhadas', value: weekHours, icon: Icons.schedule_rounded, color: Color(AppColors.primaryBlue))),
                              SizedBox(width: spacing),
                              Expanded(child: _WeekStatCard(title: 'Dias\nPresentes', value: daysPresent, icon: Icons.check_circle_rounded, color: Color(AppColors.successGreen))),
                              SizedBox(width: spacing),
                              Expanded(child: _WeekStatCard(title: 'Horas\nExtras', value: overtime, icon: Icons.trending_up_rounded, color: Theme.of(context).warningColor)),
                              SizedBox(width: spacing),
                              Expanded(child: _WeekStatCard(title: 'Saldo de\nHoras', value: balance, icon: Icons.account_balance_rounded, color: Color(AppColors.secondaryTeal))),
                            ]);
                          }),
                        ),
                        const SizedBox(height: 32),
                        Row(children: [Icon(Icons.history_rounded, color: theme.colorScheme.primary, size: 28), const SizedBox(width: 8), Text('Últimos Registros', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))]),
                        const SizedBox(height: 16),
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (recentRecords.isEmpty)
                          const SizedBox.shrink()
                        else
                          ...recentRecords.map((r) {
                            final typeStr = r['type']?.toString() ?? '';
                            final date = r['date'] ?? '—';
                            final time = (r['displayTime'] ?? '--:--').toString();
                            final location = r['location']?.toString() ?? '—';
                            final status = r['status']?.toString() ?? 'valid';
                            final total = r['total']?.toString() ?? '0h 00m';

                            int occurrence = 1;
                            try {
                              final lowerType = typeStr.toLowerCase();
                              final same = recentRecords.where((rr) {
                                final t = (rr['type'] ?? '').toString().toLowerCase();
                                return t.contains(lowerType) || lowerType.contains(t);
                              }).toList();
                              occurrence = same.indexWhere((map) => map == r) + 1;
                              if (occurrence <= 0) occurrence = 1;
                            } catch (_) {
                              occurrence = 1;
                            }

                            return ModernRecordCard(date: date, type: typeStr, time: time, location: location, status: status, total: total, occurrence: occurrence);
                          }),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final df = DateFormat("EEEE, d 'de' MMMM", 'pt_BR');
    return toBeginningOfSentenceCase(df.format(now)) ?? df.format(now);
  }
}

class _ModernStatusCard extends StatelessWidget {
  final String title;
  final String time;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isPositive;

  const _ModernStatusCard({required this.title, required this.time, required this.subtitle, required this.icon, required this.color, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.08), width: 1),
        boxShadow: [BoxShadow(color: theme.shadowColor.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(time, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.textTheme.titleLarge?.color ?? theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.85) ?? theme.colorScheme.onSurface.withValues(alpha: 0.85), fontSize: 11)),
                  ),
              ],
            ),
          ),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.18))), child: Icon(icon, color: color, size: 24)),
            if (isPositive)
              Padding(padding: const EdgeInsets.only(top: 6), child: Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 16)),
          ])
        ],
      ),
    );
  }
}

class _WeekStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _WeekStatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.14)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 3))]), child: Icon(icon, color: color, size: 24)),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 4),
      Text(title, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)), textAlign: TextAlign.center),
    ]);
  }
}

class _ModernActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ModernActionCard({required this.title, required this.icon, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
        child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: theme.shadowColor.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]),
        child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: Colors.white, size: 22), const SizedBox(height: 6), Text(title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))]),
      ),
    );
  }
}

class _HeaderBackgroundPainter extends CustomPainter {
  final ThemeData theme;
  const _HeaderBackgroundPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = theme.colorScheme.primary.withValues(alpha: 0.045);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.2), size.height * 0.75, paint);

    paint.color = theme.colorScheme.secondary.withValues(alpha: 0.035);
    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.4, size.width * 0.5, size.height * 0.65);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.9, size.width, size.height * 0.7);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    final stripePaint = Paint()..color = theme.colorScheme.onSurface.withValues(alpha: 0.02)..strokeWidth = 1.0..style = PaintingStyle.stroke;
    const stripeSpacing = 18.0;
    for (double x = -size.height; x < size.width + size.height; x += stripeSpacing) {
      final p = Path();
      p.moveTo(x, 0);
      p.lineTo(x + size.height, size.height);
      canvas.drawPath(p, stripePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

