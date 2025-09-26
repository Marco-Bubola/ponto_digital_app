import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/session_service.dart';
import '../../services/device_service.dart';
import '../../utils/constants.dart';
import '../../theme.dart';

class DevicesManagementScreen extends StatefulWidget {
  const DevicesManagementScreen({super.key});

  @override
  State<DevicesManagementScreen> createState() => _DevicesManagementScreenState();
}

class _DevicesManagementScreenState extends State<DevicesManagementScreen> {
  List<dynamic> _devices = [];
  bool _isLoading = true;
  String? _error;
  String? _currentDeviceId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _currentDeviceId = await DeviceService.getDeviceId();
    await _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await SessionService.getToken();
      if (token == null) throw Exception('Usuário não autenticado');

  final uri = Uri.parse('${AppConstants.apiBase}/api/users/devices');
  final resp = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
      if (resp.statusCode != 200) throw Exception('Falha ao carregar dispositivos (${resp.statusCode})');

      final body = json.decode(resp.body);
      setState(() {
        _devices = (body is List) ? body : (body['devices'] ?? []);
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeDevice(String deviceId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover dispositivo'),
        content: const Text('Tem certeza que deseja remover este dispositivo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remover')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await SessionService.getToken();
      if (token == null) throw Exception('Usuário não autenticado');

  final uri = Uri.parse('${AppConstants.apiBase}/api/users/devices/$deviceId');
  final resp = await http.delete(uri, headers: {'Authorization': 'Bearer $token'});
      if (resp.statusCode != 200) throw Exception('Falha ao remover dispositivo (${resp.statusCode})');

      // Recarregar lista
      await _fetchDevices();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
              theme.colorScheme.primary.withValues(alpha: 0.06),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header moderno com botão voltar (mantido como solicitado)
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
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
                      color: Color(AppColors.primaryBlue).withValues(alpha: 0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onPrimary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.devices_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Gerenciar Dispositivos', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Veja e remova dispositivos autorizados', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Conteúdo
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(child: Text(_error!))
                          : _devices.isEmpty
                              ? const Center(child: Text('Nenhum dispositivo autorizado.'))
                              : ListView.builder(
                                  itemCount: _devices.length,
                                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                                  itemBuilder: (context, index) {
                                    final d = _devices[index] as Map<String, dynamic>;
                                    final deviceId = d['deviceId'] ?? d['device_id'] ?? '';
                                    final deviceName = d['deviceName'] ?? d['device_name'] ?? 'Dispositivo';
                                    final isCurrent = _currentDeviceId != null && _currentDeviceId == deviceId;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: theme.cardColor,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                theme.colorScheme.secondary,
                                                theme.colorScheme.primary,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.smartphone_rounded, color: Colors.white),
                                        ),
                                        title: Row(
                                          children: [
                                            Expanded(child: Text(deviceName, style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface))),
                                            if (isCurrent)
                                              Container(
                                                margin: const EdgeInsets.only(left: 8),
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: theme.successColor.withValues(alpha: 0.08),
                                                  borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: theme.successColor.withValues(alpha: 0.16)),
                                                ),
                                                child: Text('Este dispositivo', style: TextStyle(color: theme.successColor, fontSize: 12)),
                                              ),
                                          ],
                                        ),
                                        subtitle: Text(deviceId, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                                        trailing: isCurrent
                                            ? Icon(Icons.check_circle, color: theme.successColor)
                                            : IconButton(
                                                icon: Icon(Icons.delete_outline, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                                                onPressed: () => _removeDevice(deviceId),
                                              ),
                                      ),
                                    );
                                  },
                                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
