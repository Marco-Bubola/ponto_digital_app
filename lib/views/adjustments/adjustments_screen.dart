import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../services/session_service.dart';

class AdjustmentsScreen extends StatefulWidget {
  const AdjustmentsScreen({super.key});

  @override
  State<AdjustmentsScreen> createState() => _AdjustmentsScreenState();
}

class _AdjustmentsScreenState extends State<AdjustmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserAndRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _justificationCtrl.dispose();
    _dateCtrl.dispose();
    _timeStartCtrl.dispose();
    _timeEndCtrl.dispose();
    super.dispose();
  }

  String? _userName;
  String? _userCpf;
  List<Map<String, dynamic>> _requests = [];
  String? _selectedType;
  String _selectedDateStr = '';
  String _timeStart = '';
  String _timeEnd = '';
  final TextEditingController _justificationCtrl = TextEditingController();
  final TextEditingController _dateCtrl = TextEditingController();
  final TextEditingController _timeStartCtrl = TextEditingController();
  final TextEditingController _timeEndCtrl = TextEditingController();
  String? _pickedFilePath;
  bool _isSending = false;

  Future<void> _loadUserAndRequests() async {
    try {
      final user = await SessionService.getUser();
      if (user != null) {
        setState(() {
          _userName = user['name']?.toString();
          _userCpf = user['cpf']?.toString();
        });
      }
    } catch (_) {}
    await _loadRequestsFromApi();
  }

  Future<void> _loadRequestsFromApi() async {
    try {
      final token = await SessionService.getToken();
      final uri = Uri.parse('http://localhost:3000/api/adjustments');
      final resp = await http.get(uri, headers: { if (token != null) 'Authorization': 'Bearer $token' });
      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);
        List<dynamic> items = [];
        if (body is List) {
          items = body;
        } else if (body is Map) {
          items = (body['items'] ?? body['data'] ?? body['records'] ?? []) as List<dynamic>;
        }
        setState(() => _requests = items.map((e) => Map<String,dynamic>.from(e as Map)).toList());
      } else {
        // keep default mock
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _sendRequest() async {
    final type = _selectedType ?? 'ajuste';
    final date = _selectedDateStr;
    final start = _timeStart;
    final end = _timeEnd;
    final desc = _justificationCtrl.text.trim();

    if (date.isEmpty && desc.isEmpty) {
      showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Preencha dados'), content: const Text('Selecione a data ou escreva uma justificativa.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))]));
      return;
    }

    final payload = {
      'type': type,
      'date': date,
      'start': start,
      'end': end,
      'description': desc,
      'cpf': _userCpf,
    };

    setState(() => _isSending = true);
    try {
      final token = await SessionService.getToken();
      final uri = Uri.parse('http://localhost:3000/api/adjustments');
      http.Response resp;
      if (_pickedFilePath != null && _pickedFilePath!.isNotEmpty) {
        // send multipart with file
        final request = http.MultipartRequest('POST', uri);
        if (token != null) request.headers['Authorization'] = 'Bearer $token';
        request.fields.addAll(payload.map((k, v) => MapEntry(k, v?.toString() ?? '')));
        final file = File(_pickedFilePath!);
        final filename = _pickedFilePath!.split(Platform.pathSeparator).last;
        request.files.add(await http.MultipartFile.fromPath('attachment', file.path, filename: filename));
        final streamed = await request.send();
        resp = await http.Response.fromStream(streamed);
      } else {
        resp = await http.post(uri, headers: { 'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token' }, body: json.encode(payload));
      }

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        // success
        if (!mounted) return;
        showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Enviado'), content: const Text('Sua solicitação foi enviada com sucesso.'), actions: [TextButton(onPressed: () { Navigator.pop(ctx); _tabController.animateTo(0); _loadRequestsFromApi(); }, child: const Text('OK'))]));
        // limpar formulário
        setState(() {
          _selectedType = null;
          _selectedDateStr = '';
          _timeStart = '';
          _timeEnd = '';
          _justificationCtrl.clear();
          _dateCtrl.clear();
          _timeStartCtrl.clear();
          _timeEndCtrl.clear();
          _pickedFilePath = null;
        });
      } else {
        String bodyMsg = resp.body;
        if (bodyMsg.isEmpty) bodyMsg = '<sem corpo>';
        if (mounted) showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Erro'), content: Text('Falha ao enviar: ${resp.statusCode}\n$bodyMsg'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))]));
      }
    } catch (e) {
      if (mounted) showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Erro'), content: Text('Falha de conexão: $e'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))]));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedFilePath = result.files.first.path;
        });
      }
    } catch (e) {
      // ignore for now
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
              Color(AppColors.warningYellow).withValues(alpha: 0.1),
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
                      Color(AppColors.warningYellow),
                      Color(AppColors.warningYellow).withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Color(AppColors.warningYellow).withValues(alpha: 0.3),
                      spreadRadius: 2,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Solicitações',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userName != null ? 'Olá, $_userName' : 'Gerencie seus ajustes de ponto',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // TabBar moderno
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
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
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Color(AppColors.warningYellow),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorPadding: const EdgeInsets.all(4),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'Minhas Solicitações'),
                    Tab(text: 'Nova Solicitação'),
                  ],
                ),
              ),
              
              // Conteúdo das abas
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRequestsList(),
                    _buildNewRequestForm(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsList() {
    return RefreshIndicator(
      onRefresh: () async => await _loadRequestsFromApi(),
      child: _requests.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              children: const [
                SizedBox(height: 60),
                Center(child: Text('Sem solicitações. Puxe para atualizar.')),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _requests.length,
              itemBuilder: (context, i) {
                final r = _requests[i];
                return _RequestCard(
                  id: r['id']?.toString() ?? '#${i + 1}',
                  type: r['type']?.toString() ?? 'Ajuste',
                  date: r['date']?.toString() ?? '',
                  status: r['status']?.toString() ?? 'Pendente',
                  description: r['description']?.toString() ?? '',
                  statusColor: r['status'] == 'Aprovado' ? Color(AppColors.successGreen) : r['status'] == 'Rejeitado' ? Color(AppColors.errorRed) : Color(AppColors.warningYellow),
                  onTap: () => _showRequestDetails(r['id']?.toString() ?? '#${i + 1}'),
                );
              },
            ),
    );
  }

  Widget _buildNewRequestForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.edit_note,
                        color: Color(AppColors.primaryBlue),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Nova Solicitação',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Tipo de solicitação
                  Text(
                    'Tipo de Solicitação',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    hint: const Text('Selecione o tipo'),
                    items: const [
                      DropdownMenuItem(
                        value: 'ajuste',
                        child: Text('Ajuste de Horário'),
                      ),
                      DropdownMenuItem(
                        value: 'ausencia',
                        child: Text('Ausência Justificada'),
                      ),
                      DropdownMenuItem(
                        value: 'extras',
                        child: Text('Horas Extras'),
                      ),
                      DropdownMenuItem(
                        value: 'atestado',
                        child: Text('Atestado Médico'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedType = value);
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Data
                  Text(
                    'Data',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      hintText: 'Selecione a data',
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    controller: _dateCtrl,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDateStr = '${picked.day.toString().padLeft(2,'0')}/${picked.month.toString().padLeft(2,'0')}/${picked.year}';
                          _dateCtrl.text = _selectedDateStr;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Horário (se aplicável)
                  Text(
                    'Horário',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            hintText: 'Início',
                            suffixIcon: const Icon(Icons.access_time),
                          ),
                          readOnly: true,
                          controller: _timeStartCtrl,
                          onTap: () async {
                            final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                            if (t != null) {
                              setState(() {
                                _timeStart = t.format(context);
                                _timeStartCtrl.text = _timeStart;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            hintText: 'Fim',
                            suffixIcon: const Icon(Icons.access_time),
                          ),
                          readOnly: true,
                          controller: _timeEndCtrl,
                          onTap: () async {
                            final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                            if (t != null) {
                              setState(() {
                                _timeEnd = t.format(context);
                                _timeEndCtrl.text = _timeEnd;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Justificativa
                  Text(
                    'Justificativa',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _justificationCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      hintText: 'Descreva o motivo da solicitação...',
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Anexo
                  InkWell(
                    onTap: () async => await _pickAttachment(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey[300]!,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_upload,
                            size: 48,
                            color: Color(AppColors.neutralGray),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _pickedFilePath == null ? 'Clique para anexar documentos' : 'Anexo: ${_pickedFilePath!.split(Platform.pathSeparator).last}',
                            style: TextStyle(
                              color: Color(AppColors.neutralGray),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'PDF, JPG, PNG (máx. 5MB)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(AppColors.neutralGray),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Botão de envio
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : () async { await _sendRequest(); },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(AppColors.primaryBlue),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text(
                              'Enviar Solicitação',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRequestDetails(String id) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Solicitação $id',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow('Tipo:', 'Ajuste de Horário'),
            _DetailRow('Data:', '15/09/2025'),
            _DetailRow('Horário:', '08:15 → 08:00'),
            _DetailRow('Status:', 'Pendente'),
            _DetailRow('Justificativa:', 'Atraso devido ao trânsito intenso na Marginal Tietê.'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // _submitRequest removed: replaced by _sendRequest which calls backend and updates list
}

class _RequestCard extends StatelessWidget {
  final String id;
  final String type;
  final String date;
  final String status;
  final String description;
  final Color statusColor;
  final VoidCallback onTap;

  const _RequestCard({
    required this.id,
    required this.type,
    required this.date,
    required this.status,
    required this.description,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    id,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Color(AppColors.primaryBlue),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                type,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Color(AppColors.neutralGray),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                date,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Color(AppColors.neutralGray),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
