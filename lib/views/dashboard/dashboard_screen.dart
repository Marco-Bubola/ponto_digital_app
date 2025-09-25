import 'package:flutter/material.dart';
import '../timecard/timecard_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import '../adjustments/adjustments_screen.dart';
import '../reports/reports_screen.dart';
import '../../utils/constants.dart';
import '../../services/session_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
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
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Color(AppColors.primaryBlue),
        unselectedItemColor: Color(AppColors.neutralGray),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time_outlined),
            activeIcon: Icon(Icons.access_time),
            label: 'Ponto',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Histórico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Configurações',
          ),
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
  // Campos dinâmicos do usuário (padrões quando não houver dados)
  String entryTime = '--:--';
  String exitTime = '--:--';
  String entrySubtitle = 'Aguardando';
  String exitSubtitle = 'Aguardando';

  String weekHours = '0h 00m';
  String daysPresent = '0/0';
  String overtime = '0h 00m';
  String balance = '+0h 00m';

  List<Map<String, dynamic>> recentRecords = [];
  // registros brutos (armazenados temporariamente dentro do fetch)
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
          userName = user['name'] ?? 'Usuário';
          companyName = (user['company'] != null && user['company']['name'] != null)
              ? user['company']['name']
              : '';
          // Preencher dados dinâmicos se disponíveis
          final stats = user['stats'];
          if (stats != null && stats is Map) {
            weekHours = stats['weekHours'] ?? weekHours;
            daysPresent = stats['daysPresent']?.toString() ?? daysPresent;
            overtime = stats['overtime'] ?? overtime;
            balance = stats['balance'] ?? balance;
          }

          // Ponto do dia
          final today = user['today'];
          if (today != null && today is Map) {
            entryTime = today['entryTime'] ?? entryTime;
            exitTime = today['exitTime'] ?? exitTime;
            entrySubtitle = today['entrySubtitle'] ?? entrySubtitle;
            exitSubtitle = today['exitSubtitle'] ?? exitSubtitle;
          }

          // Registros recentes
          final recs = user['recentRecords'];
          if (recs != null && recs is List) {
            recentRecords = recs.map<Map<String, dynamic>>((r) {
              try {
                return {
                  'date': r['date']?.toString() ?? '—',
                  'entry': r['entry']?.toString() ?? '--:--',
                  'exit': r['exit']?.toString() ?? '--:--',
                  'total': r['total']?.toString() ?? '0h 00m',
                  'type': r['type'] ?? r['action'] ?? '',
                  'location': r['location'],
                  'status': r['status'] ?? 'valid',
                };
              } catch (e) {
                return {'date': '—', 'entry': '--:--', 'exit': '--:--', 'total': '0h 00m'};
              }
            }).toList();
          }
        });
      }
    } catch (_) {}

    // Buscar registros diretamente da API para garantir dados atualizados
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
            // Parsear timestamps e normalizar registros
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

            // Ordenar por timestamp desc (mais recente primeiro)
            parsed.sort((a, b) {
              final aTs = a['_ts'] as DateTime?;
              final bTs = b['_ts'] as DateTime?;
              if (aTs == null && bTs == null) return 0;
              if (aTs == null) return 1;
              if (bTs == null) return -1;
              return bTs.compareTo(aTs);
            });

            // parsed já contém os registros normalizados para uso local

            // Registros do dia atual
            final today = DateTime.now();
            bool sameDay(DateTime d) => d.year == today.year && d.month == today.month && d.day == today.day;
            final todayRecords = parsed.where((m) => (m['_ts'] as DateTime?) != null && sameDay(m['_ts'] as DateTime)).toList();

            // Entrada: menor horário do dia com tipo entrada
            String fmtTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

            DateTime? entradaDt;
            DateTime? saidaDt;
            for (final r in todayRecords) {
              final typeStr = (r['type'] ?? r['action'] ?? '').toString().toLowerCase();
              final ts = r['_ts'] as DateTime?;
              if (ts == null) continue;
              if (entradaDt == null && typeStr.contains('entrada') || entradaDt == null && typeStr.contains('entry')) {
                entradaDt = ts;
              }
              if (typeStr.contains('saida') || typeStr.contains('saída') || typeStr.contains('exit')) {
                if (saidaDt == null || ts.isAfter(saidaDt)) saidaDt = ts;
              }
            }

            if (entradaDt != null) entryTime = fmtTime(entradaDt);
            if (saidaDt != null) exitTime = fmtTime(saidaDt);

            // Subtitulo com local do último registro do dia (se houver)
            if (todayRecords.isNotEmpty) {
              final last = todayRecords.first; // parsed sorted desc
              entrySubtitle = last['location'] is Map ? (last['location']['name'] ?? entrySubtitle) : (last['location']?.toString() ?? entrySubtitle);
            }

            // Estatísticas da semana (baseado na semana atual: segunda -> domingo)
            final now = DateTime.now();
            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
            final endOfWeek = startOfWeek.add(const Duration(days: 6));
            final weekRecords = parsed.where((m) {
              final dt = m['_ts'] as DateTime?;
              if (dt == null) return false;
              return !(dt.isBefore(startOfWeek) || dt.isAfter(endOfWeek));
            }).toList();

            Duration parseDurationString(String s) {
              try {
                final hMatch = RegExp(r"(\d+)h").firstMatch(s);
                final mMatch = RegExp(r"(\d+)m").firstMatch(s);
                final h = hMatch != null ? int.parse(hMatch.group(1)!) : 0;
                final mm = mMatch != null ? int.parse(mMatch.group(1)!) : 0;
                return Duration(hours: h, minutes: mm);
              } catch (_) {
                return Duration.zero;
              }
            }

            Duration totalWeek = Duration.zero;
            final presentDays = <String>{};
            for (final r in weekRecords) {
              final dt = r['_ts'] as DateTime?;
              if (dt != null) presentDays.add('${dt.year}-${dt.month}-${dt.day}');
              if (r['total'] != null && r['total'].toString().isNotEmpty) {
                totalWeek += parseDurationString(r['total'].toString());
              } else if (r['entryTime'] != null && r['exitTime'] != null) {
                try {
                  final e = DateTime.parse(r['entryTime'].toString()).toLocal();
                  final s = DateTime.parse(r['exitTime'].toString()).toLocal();
                  final dayDur = s.difference(e);
                  if (!dayDur.isNegative) totalWeek += dayDur;
                } catch (_) {}
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
            if (diff.isNegative) {
              overtime = '0h 00m';
              balance = fmtDur(diff);
            } else {
              overtime = fmtDur(diff);
              balance = '+$overtime';
            }

            // Mapear últimos registros para exibição (máx 5), mantendo metadados
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
              // displayTime: prefer entry, else timestamp time
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
    return CustomScrollView(
      slivers: [
        // Header com gradiente
        SliverToBoxAdapter(
          child: Container(
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
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Saudação e avatar
                    Row(
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
                            radius: 35,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Color(AppColors.primaryBlue),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Olá, $userName 👋',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    companyName.isNotEmpty ? companyName : 'Ponto Digital',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Hoje é ${_getFormattedDate()}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                             
                              
                            ],
                          ),
                        ),
                        // Notificações
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                            ),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Status cards em linha (valores dinâmicos ou placeholders)
                    Row(
                      children: [
                        Expanded(
                          child: _ModernStatusCard(
                            title: 'Entrada',
                            time: entryTime,
                            subtitle: entrySubtitle,
                            icon: Icons.login_rounded,
                            color: Colors.green[400]!,
                            isPositive: entryTime != '--:--',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ModernStatusCard(
                            title: 'Saída',
                            time: exitTime,
                            subtitle: exitSubtitle,
                            icon: Icons.logout_rounded,
                            color: Colors.orange[400]!,
                            isPositive: exitTime != '--:--',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Conteúdo principal com pull-to-refresh
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -20),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
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

                        // Banner de erro
                        if (_error != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(AppColors.errorRed).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Color(AppColors.errorRed).withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Color(AppColors.errorRed), size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_error!, style: TextStyle(color: Color(AppColors.errorRed)))),
                                IconButton(
                                  onPressed: () => setState(() => _error = null),
                                  icon: Icon(Icons.close, color: Color(AppColors.errorRed), size: 18),
                                ),
                              ],
                            ),
                          ),

                        // Seção de Ações Rápidas
                        Row(
                          children: [
                            Icon(
                              Icons.flash_on_rounded,
                              color: Color(AppColors.primaryBlue),
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ações Rápidas',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Alinhar os botões de ações rápidas na mesma linha
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: _ModernActionCard(
                                title: 'Registrar\nPonto',
                                icon: Icons.fingerprint_rounded,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(AppColors.primaryBlue),
                                    Color(AppColors.primaryBlue).withValues(alpha: 0.8),
                                  ],
                                ),
                                onTap: () {
                                  // Navegar via callback para preservar a BottomNavigationBar
                                  if (widget.onNavigate != null) {
                                    widget.onNavigate!(1);
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const TimecardScreen(),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _ModernActionCard(
                                title: 'Espelho\nDigital',
                                icon: Icons.receipt_long_rounded,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(AppColors.successGreen),
                                    Color(AppColors.successGreen).withValues(alpha: 0.8),
                                  ],
                                ),
                                onTap: () {
                                  if (widget.onNavigate != null) {
                                    widget.onNavigate!(2);
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const HistoryScreen(),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _ModernActionCard(
                                title: 'Solicitações',
                                icon: Icons.edit_note_rounded,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(AppColors.warningYellow),
                                    Color(AppColors.warningYellow).withValues(alpha: 0.8),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AdjustmentsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _ModernActionCard(
                                title: 'Relatórios',
                                icon: Icons.analytics_rounded,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(AppColors.secondaryTeal),
                                    Color(AppColors.secondaryTeal).withValues(alpha: 0.8),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ReportsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Estatísticas da semana
                        Row(
                          children: [
                            Icon(
                              Icons.bar_chart_rounded,
                              color: Color(AppColors.primaryBlue),
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Esta Semana',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

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
                            children: [
                              // Mostrar os 4 cartões em uma única linha responsiva
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final spacing = 12.0;
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: _WeekStatCard(
                                          title: 'Horas\nTrabalhadas',
                                          value: weekHours,
                                          icon: Icons.schedule_rounded,
                                          color: Color(AppColors.primaryBlue),
                                        ),
                                      ),
                                      SizedBox(width: spacing),
                                      Expanded(
                                        child: _WeekStatCard(
                                          title: 'Dias\nPresentes',
                                          value: daysPresent,
                                          icon: Icons.check_circle_rounded,
                                          color: Color(AppColors.successGreen),
                                        ),
                                      ),
                                      SizedBox(width: spacing),
                                      Expanded(
                                        child: _WeekStatCard(
                                          title: 'Horas\nExtras',
                                          value: overtime,
                                          icon: Icons.trending_up_rounded,
                                          color: Color(AppColors.warningYellow),
                                        ),
                                      ),
                                      SizedBox(width: spacing),
                                      Expanded(
                                        child: _WeekStatCard(
                                          title: 'Saldo de\nHoras',
                                          value: balance,
                                          icon: Icons.account_balance_rounded,
                                          color: Color(AppColors.secondaryTeal),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Últimos registros
                        Row(
                          children: [
                            Icon(
                              Icons.history_rounded,
                              color: Color(AppColors.primaryBlue),
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Últimos Registros',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Registros recentes (dinâmicos, se houver)
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

                            // compute occurrence among recentRecords (best-effort)
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

                            return ModernRecordCard(
                              date: date,
                              type: typeStr,
                              time: time,
                              location: location,
                              status: status,
                              total: total,
                              occurrence: occurrence,
                            );
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
    // Formatação local pt-BR
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

  const _ModernStatusCard({
    required this.title,
    required this.time,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
              if (isPositive)
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 16,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            time,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _ModernActionCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 140,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 36,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
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
      ),
    );
  }
}

class _WeekStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _WeekStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// _RecentRecordCardModern removed — use ModernRecordCard from widgets
