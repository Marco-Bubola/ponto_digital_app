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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    const DashboardContent(),
    const TimecardScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ponto Digital'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implementar notificações
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
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
  const DashboardContent({super.key});

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

  List<Map<String, String>> recentRecords = [];
  List<Map<String, dynamic>> _records = [];
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
            recentRecords = recs.map<Map<String, String>>((r) {
              try {
                return {
                  'date': r['date']?.toString() ?? '—',
                  'entry': r['entry']?.toString() ?? '--:--',
                  'exit': r['exit']?.toString() ?? '--:--',
                  'total': r['total']?.toString() ?? '0h 00m',
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
            _records = recs.map((r) => Map<String, dynamic>.from(r as Map)).toList();

            // Atualizar visualizações com base no registro mais recente
            if (_records.isNotEmpty) {
              final first = _records.first;
              final ts = first['timestamp'] ?? first['createdAt'];
              if (ts != null) {
                try {
                  final dt = DateTime.parse(ts.toString());
                  entryTime = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                } catch (_) {
                  entryTime = ts.toString();
                }
              }

              entrySubtitle = first['location'] is Map ? (first['location']['name'] ?? entrySubtitle) : (first['location']?.toString() ?? entrySubtitle);
            }

            // Mapear últimos registros para exibição (máx 5)
            final dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');
            final timeFmt = DateFormat('HH:mm', 'pt_BR');
            recentRecords = _records.take(5).map<Map<String, String>>((r) {
              String date = '—';
              String entry = '--:--';
              String exit = '--:--';
              String total = '0h 00m';

              final ts = r['timestamp'] ?? r['createdAt'];
              if (ts != null) {
                try {
                  final dt = DateTime.parse(ts.toString());
                  date = dateFmt.format(dt);
                } catch (_) {
                  date = ts.toString();
                }
              }

              final type = r['type'] ?? r['action'] ?? '';
              if (type != null && type.toString().isNotEmpty) {
                entry = type.toString();
              }

              if (r['entryTime'] != null) {
                try {
                  final dt = DateTime.parse(r['entryTime'].toString());
                  entry = timeFmt.format(dt);
                } catch (_) {
                  entry = r['entryTime'].toString();
                }
              }
              if (r['exitTime'] != null) {
                try {
                  final dt = DateTime.parse(r['exitTime'].toString());
                  exit = timeFmt.format(dt);
                } catch (_) {
                  exit = r['exitTime'].toString();
                }
              }
              if (r['total'] != null) total = r['total'].toString();

              return {
                'date': date,
                'entry': entry,
                'exit': exit,
                'total': total,
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
                              // Refresh button & loading
                              Row(
                                children: [
                                  if (_isLoading) const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  ),
                                  IconButton(
                                    onPressed: _isLoading ? null : () async => await _fetchTimeRecords(),
                                    icon: const Icon(Icons.refresh, color: Colors.white),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                              
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const TimecardScreen(),
                                    ),
                                  );
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const HistoryScreen(),
                                    ),
                                  );
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
                              Row(
                                children: [
                                  Expanded(
                                    child: _WeekStatCard(
                                      title: 'Horas\nTrabalhadas',
                                      value: weekHours,
                                      icon: Icons.schedule_rounded,
                                      color: Color(AppColors.primaryBlue),
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 60,
                                    color: Colors.grey[300],
                                    margin: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  Expanded(
                                    child: _WeekStatCard(
                                      title: 'Dias\nPresentes',
                                      value: daysPresent,
                                      icon: Icons.check_circle_rounded,
                                      color: Color(AppColors.successGreen),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Divider(color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _WeekStatCard(
                                      title: 'Horas\nExtras',
                                      value: overtime,
                                      icon: Icons.trending_up_rounded,
                                      color: Color(AppColors.warningYellow),
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 60,
                                    color: Colors.grey[300],
                                    margin: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  Expanded(
                                    child: _WeekStatCard(
                                      title: 'Saldo de\nHoras',
                                      value: balance,
                                      icon: Icons.account_balance_rounded,
                                      color: Color(AppColors.secondaryTeal),
                                    ),
                                  ),
                                ],
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
                          ...recentRecords.map((r) => _RecentRecordCard(
                            date: r['date'] ?? '—',
                            entry: r['entry'] ?? '--:--',
                            exit: r['exit'] ?? '--:--',
                            total: r['total'] ?? '0h 00m',
                          )),

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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 36,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
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

class _RecentRecordCard extends StatelessWidget {
  final String date;
  final String entry;
  final String exit;
  final String total;

  const _RecentRecordCard({
    required this.date,
    required this.entry,
    required this.exit,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(AppColors.primaryBlue).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.today_rounded,
              color: Color(AppColors.primaryBlue),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$entry - $exit',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            total,
            style: TextStyle(
              color: Color(AppColors.successGreen),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
