import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/session_service.dart';
import '../../services/device_service.dart';
import '../../utils/constants.dart';

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
    _loadDevices();
    // obter deviceId local para destacar na lista
    DeviceService.getDeviceId().then((id) {
      if (mounted) setState(() => _currentDeviceId = id);
    });
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await SessionService.getToken();
      final uri = Uri.parse('http://localhost:3000/api/users/devices');
      final resp = await http.get(uri, headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      });

      if (resp.statusCode == 200) {
        final body = json.decode(resp.body) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          _devices = (body['devices'] as List<dynamic>?) ?? [];
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _error = 'Erro ao carregar dispositivos: ${resp.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Falha de conexão';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeDevice(String deviceId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover dispositivo'),
        content: const Text('Deseja realmente remover este dispositivo autorizado? Ele perderá acesso à sua conta.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Remover')),
        ],
      ),
    );

    if (!mounted) return;
    if (confirm != true) return;

    try {
      final token = await SessionService.getToken();
      final uri = Uri.parse('http://localhost:3000/api/users/devices/$deviceId');
      final resp = await http.delete(uri, headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      });

      if (resp.statusCode == 200) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dispositivo removido')));
        await _loadDevices();
      } else {
        final body = resp.body;
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao remover: ${resp.statusCode} - $body')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha de conexão')));
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
              Color(AppColors.primaryBlue).withValues(alpha: 0.08),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header moderno com botão voltar
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
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
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
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withValues(alpha: 0.06),
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
                                                Color(AppColors.secondaryTeal),
                                                Color(AppColors.primaryBlue),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.smartphone_rounded, color: Colors.white),
                                        ),
                                        title: Row(
                                          children: [
                                            Expanded(child: Text(deviceName, style: const TextStyle(fontWeight: FontWeight.w600))),
                                            if (isCurrent)
                                              Container(
                                                margin: const EdgeInsets.only(left: 8),
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Color(AppColors.successGreen).withValues(alpha: 0.08),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: Color(AppColors.successGreen).withValues(alpha: 0.16)),
                                                ),
                                                child: Text('Este dispositivo', style: TextStyle(color: Color(AppColors.successGreen), fontSize: 12)),
                                              ),
                                          ],
                                        ),
                                        subtitle: Text(deviceId, style: TextStyle(color: Colors.grey[700])),
                                        trailing: isCurrent
                                            ? Icon(Icons.check_circle, color: Color(AppColors.successGreen))
                                            : IconButton(
                                                icon: const Icon(Icons.delete_outline),
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
