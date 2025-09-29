import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../models/notification_item.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final DateFormat _fmt = DateFormat('dd/MM/yyyy HH:mm');
  NotificationService? _svc;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    NotificationService.getInstance().then((s) {
      _svc = s;
      setState(() {});
    });
  }

  Future<void> _refresh() async {
    // pequena espera para efeito de refresh; NotificationService notifica automaticamente
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {});
  }

  void _simulate() async {
    final item = NotificationItem(
      id: const Uuid().v4(),
      title: 'Nova notificação',
      body: 'Notificação gerada localmente',
      createdAt: DateTime.now(),
    );
    await _svc?.add(item);
    setState(() {});
  }

  

  // Compact header used inside a Row (no search field) to avoid overflow
  Widget _buildCompactHeader(BuildContext context, List<NotificationItem> list) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Notificações', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Últimas atualizações e alertas do sistema', style: theme.textTheme.bodySmall),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      // AppBar removed in favor of an inline modern header with back button
      body: _svc == null
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder<List<NotificationItem>>(
              valueListenable: _svc!.notifications,
              builder: (context, list, _) {
                final filtered = list.where((n) => _filter.isEmpty || n.title.toLowerCase().contains(_filter.toLowerCase()) || n.body.toLowerCase().contains(_filter.toLowerCase())).toList();
                return SafeArea(
                  child: Column(
                    children: [
                      // Top modern header with back button and clear action
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => Navigator.of(context).maybePop(),
                              tooltip: 'Voltar',
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: _buildCompactHeader(context, list)),
                            IconButton(
                              icon: const Icon(Icons.delete_sweep),
                              onPressed: () async {
                                await _svc?.clear();
                                setState(() {});
                              },
                              tooltip: 'Limpar tudo',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Search field placed below header to avoid layout overflow
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextField(
                          onChanged: (v) => setState(() => _filter = v.trim()),
                          decoration: InputDecoration(
                            hintText: 'Procurar notificações',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
                            filled: true,
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _refresh,
                          child: filtered.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  children: [
                                    const SizedBox(height: 40),
                                    Center(child: Text('Nenhuma notificação', style: theme.textTheme.bodyLarge)),
                                  ],
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 92, top: 6),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, idx) {
                                    final n = filtered[idx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Dismissible(
                                key: ValueKey(n.id),
                                background: Container(
                                  decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(12)),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                direction: DismissDirection.endToStart,
                                onDismissed: (_) => setState(() => _svc?.remove(n.id)),
                                child: Card(
                                  elevation: n.read ? 1 : 4,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  color: n.read ? theme.cardColor : theme.colorScheme.primary.withAlpha(18),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    leading: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: theme.colorScheme.primaryContainer,
                                      child: Icon(Icons.message_rounded, color: theme.colorScheme.onPrimaryContainer),
                                    ),
                                    title: Text(n.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                             subtitle: Text('${n.body}\n${_fmt.format(n.createdAt)}', maxLines: 2, overflow: TextOverflow.ellipsis),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          iconSize: 20,
                                          padding: const EdgeInsets.all(6),
                                          constraints: const BoxConstraints(),
                                          icon: Icon(n.read ? Icons.mark_email_read : Icons.mark_email_unread),
                                          onPressed: () => setState(() => _svc?.markRead(n.id, read: !n.read)),
                                          tooltip: n.read ? 'Marcar como não lida' : 'Marcar como lida',
                                        ),
                                        PopupMenuButton<int>(
                                          padding: EdgeInsets.zero,
                                          itemBuilder: (ctx) => [
                                            const PopupMenuItem(value: 1, child: Text('Compartilhar')),
                                            const PopupMenuItem(value: 2, child: Text('Remover')),
                                          ],
                                          onSelected: (v) {
                                            if (v == 2) setState(() => _svc?.remove(n.id));
                                          },
                                        ),
                                      ],
                                    ),
                                    onTap: () => setState(() => _svc?.markRead(n.id, read: true)),
                                  ),
                                ),
                              ),
                            );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _simulate, label: const Text('Simular'), icon: const Icon(Icons.send)),
    );
  }
}
