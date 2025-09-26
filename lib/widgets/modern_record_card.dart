import 'package:flutter/material.dart';
// import '../utils/constants.dart'; // not needed here anymore
import '../theme.dart';

class ModernRecordCard extends StatelessWidget {
  final String date;
  final String type;
  final String time;
  final String location;
  final String status;
  final String total;
  final int? occurrence;

  const ModernRecordCard({
    super.key,
    required this.date,
    required this.type,
    required this.time,
    required this.location,
    required this.status,
    required this.total,
    this.occurrence,
  });

  // removed context-free helper; status color is computed inside build

  String _getStatusLabel() {
    final s = status.toString().toLowerCase();
    if (s.contains('pend') || s.contains('pending')) return 'Pendente';
    if (s.contains('inv') || s.contains('invalid') || s.contains('invál')) return 'Inválido';
    return 'Confirmado';
  }

  String _typeLabel() {
    final t = type.toString().toLowerCase();
    if (t.contains('entrada') || t.contains('entry')) return 'Entrada';
    if (t.contains('pausa')) return 'Pausa';
    if (t.contains('retorno')) return 'Retorno';
    if (t.contains('saida') || t.contains('exit')) return 'Saída';
    return t.isNotEmpty ? t : 'Registro';
  }

  IconData _typeIcon() {
    final t = type.toString().toLowerCase();
    if (t.contains('entrada') || t.contains('entry')) return Icons.login_rounded;
    if (t.contains('pausa')) return Icons.pause_circle_rounded;
    if (t.contains('retorno')) return Icons.play_circle_rounded;
    if (t.contains('saida') || t.contains('exit')) return Icons.logout_rounded;
    return Icons.history_rounded;
  }

  String _shortTypeLabel() {
    final t = type.toString().toLowerCase();
    if (t.contains('entrada') || t.contains('entry')) return 'Entrada';
    if (t.contains('pausa') || t.contains('pause')) return 'Pausa';
    if (t.contains('retorno') || t.contains('return')) return 'Retorno';
    if (t.contains('saida') || t.contains('exit')) return 'Saída';
    return 'Registro';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color statusColor;
    final s = status.toString().toLowerCase();
  if (s.contains('pend') || s.contains('pending')) { statusColor = theme.warningColor; }
  else if (s.contains('inv') || s.contains('invalid') || s.contains('invál')) { statusColor = theme.errorColor; }
  else { statusColor = theme.successColor; }
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.06),
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
                    gradient: LinearGradient(
                      colors: [
                        statusColor,
                        statusColor.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                child: Builder(builder: (context) {
                  final base = statusColor;
                  final fg = base.computeLuminance() > 0.5 ? Colors.black : Colors.white;
                  return Icon(_typeIcon(), color: fg, size: 22);
                }),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                          Text(
                            _typeLabel().toLowerCase().contains('entrada') ? '🌅' : (_typeLabel().toLowerCase().contains('pausa') ? '☕' : (_typeLabel().toLowerCase().contains('retorno') ? '💼' : '🏁')),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              Text(
                                _typeLabel(),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              if (occurrence != null && occurrence! >= 2) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: statusColor.withValues(alpha: 0.18)),
                                  ),
                                  child: Text(
                                    '$occurrenceª ${_shortTypeLabel()}',
                                      style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      time,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                        const SizedBox(width: 6),
                        Expanded(child: Text(location, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12))),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    date,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _getStatusLabel(),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
