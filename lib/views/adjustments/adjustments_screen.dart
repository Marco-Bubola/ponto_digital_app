import 'package:flutter/material.dart';
import '../../utils/constants.dart';

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              Color(AppColors.warningYellow).withOpacity(0.1),
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
                      Color(AppColors.warningYellow).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Color(AppColors.warningYellow).withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Solicitações',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Gerencie seus ajustes de ponto',
                            style: TextStyle(
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
                      color: Colors.grey.withOpacity(0.1),
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
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _RequestCard(
          id: '#001',
          type: 'Ajuste de Horário',
          date: '15/09/2025',
          status: 'Pendente',
          description: 'Ajuste de entrada - 08:15 para 08:00',
          statusColor: Color(AppColors.warningYellow),
          onTap: () => _showRequestDetails('#001'),
        ),
        _RequestCard(
          id: '#002',
          type: 'Ausência Justificada',
          date: '10/09/2025',
          status: 'Aprovado',
          description: 'Consulta médica - 14:00 às 16:00',
          statusColor: Color(AppColors.successGreen),
          onTap: () => _showRequestDetails('#002'),
        ),
        _RequestCard(
          id: '#003',
          type: 'Horas Extras',
          date: '05/09/2025',
          status: 'Rejeitado',
          description: 'Projeto urgente - 2 horas extras',
          statusColor: Color(AppColors.errorRed),
          onTap: () => _showRequestDetails('#003'),
        ),
      ],
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
                      // TODO: Implementar lógica
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
                    onTap: () async {
                      await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      // TODO: Implementar lógica
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
                          onTap: () {
                            // TODO: Implementar seletor de hora
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
                          onTap: () {
                            // TODO: Implementar seletor de hora
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
                  Container(
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
                          'Clique para anexar documentos',
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
                  const SizedBox(height: 32),
                  
                  // Botão de envio
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _submitRequest();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(AppColors.primaryBlue),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
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

  void _submitRequest() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitação Enviada'),
        content: const Text('Sua solicitação foi enviada com sucesso e está aguardando aprovação.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _tabController.animateTo(0);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
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
                      color: statusColor.withOpacity(0.1),
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