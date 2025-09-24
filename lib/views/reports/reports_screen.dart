import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'month';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        backgroundColor: Color(AppColors.primaryBlue),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () {
              _showExportOptions();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filtro de período
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.filter_list,
                          color: Color(AppColors.primaryBlue),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Período',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        _PeriodChip(
                          label: 'Esta Semana',
                          value: 'week',
                          selected: _selectedPeriod == 'week',
                          onSelected: (value) {
                            setState(() {
                              _selectedPeriod = value;
                            });
                          },
                        ),
                        _PeriodChip(
                          label: 'Este Mês',
                          value: 'month',
                          selected: _selectedPeriod == 'month',
                          onSelected: (value) {
                            setState(() {
                              _selectedPeriod = value;
                            });
                          },
                        ),
                        _PeriodChip(
                          label: 'Trimestre',
                          value: 'quarter',
                          selected: _selectedPeriod == 'quarter',
                          onSelected: (value) {
                            setState(() {
                              _selectedPeriod = value;
                            });
                          },
                        ),
                        _PeriodChip(
                          label: 'Personalizado',
                          value: 'custom',
                          selected: _selectedPeriod == 'custom',
                          onSelected: (value) {
                            setState(() {
                              _selectedPeriod = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Resumo geral
            Text(
              'Resumo Geral',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _SummaryCard(
                  title: 'Horas Trabalhadas',
                  value: '168h 45m',
                  icon: Icons.access_time,
                  color: Color(AppColors.primaryBlue),
                  trend: '+5%',
                ),
                _SummaryCard(
                  title: 'Dias Trabalhados',
                  value: '22/22',
                  icon: Icons.calendar_today,
                  color: Color(AppColors.successGreen),
                  trend: '100%',
                ),
                _SummaryCard(
                  title: 'Horas Extras',
                  value: '8h 30m',
                  icon: Icons.add_circle,
                  color: Color(AppColors.warningYellow),
                  trend: '+12%',
                ),
                _SummaryCard(
                  title: 'Faltas',
                  value: '0',
                  icon: Icons.cancel,
                  color: Color(AppColors.errorRed),
                  trend: '0%',
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Histórico de pontos
            Text(
              'Histórico Detalhado',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            
            Card(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(AppColors.primaryBlue),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Data',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Entrada',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Saída',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Total',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      return _TimeRecordRow(
                        date: '${20 - index}/09/2025',
                        entry: '08:00',
                        exit: '17:00',
                        total: '8h 00m',
                        isOdd: index % 2 == 1,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Gráfico de frequência (placeholder)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Frequência Semanal',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bar_chart,
                              size: 48,
                              color: Color(AppColors.neutralGray),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Gráfico de Frequência',
                              style: TextStyle(
                                color: Color(AppColors.neutralGray),
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Em desenvolvimento',
                              style: TextStyle(
                                color: Color(AppColors.neutralGray),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Exportar Relatório',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                Icons.picture_as_pdf,
                color: Color(AppColors.errorRed),
              ),
              title: const Text('Exportar como PDF'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar exportação PDF
              },
            ),
            ListTile(
              leading: Icon(
                Icons.table_view,
                color: Color(AppColors.successGreen),
              ),
              title: const Text('Exportar como Excel'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar exportação Excel
              },
            ),
            ListTile(
              leading: Icon(
                Icons.email,
                color: Color(AppColors.primaryBlue),
              ),
              title: const Text('Enviar por Email'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar envio por email
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final ValueChanged<String> onSelected;

  const _PeriodChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (bool value) {
        if (value) {
          onSelected(this.value);
        }
      },
      selectedColor: Color(AppColors.primaryBlue).withValues(alpha: 0.2),
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

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Color(AppColors.neutralGray),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

  const _TimeRecordRow({
    required this.date,
    required this.entry,
    required this.exit,
    required this.total,
    required this.isOdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isOdd ? Colors.grey[50] : Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(date),
          ),
          Expanded(
            child: Text(entry),
          ),
          Expanded(
            child: Text(exit),
          ),
          Expanded(
            child: Text(
              total,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
