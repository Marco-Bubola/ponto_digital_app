import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        'question': 'Como registrar meu ponto?',
        'answer': 'Para registrar seu ponto, acesse a aba "Ponto", selecione o tipo de registro (Entrada, Pausa, Retorno ou Saída) e toque no botão correspondente. O sistema validará sua localização e identidade automaticamente.',
      },
      {
        'question': 'Como visualizar meu histórico de registros?',
        'answer': 'Acesse a aba "Histórico" para ver todos os seus registros. Você pode filtrar por data específica usando o seletor de data no topo da tela.',
      },
      {
        'question': 'Por que meu registro aparece como "Pendente"?',
        'answer': 'Um registro pode aparecer como pendente quando há alguma inconsistência detectada pelo sistema, como localização diferente do habitual ou horário fora do padrão. Entre em contato com o RH para regularizar.',
      },
      {
        'question': 'Como alterar meus dados pessoais?',
        'answer': 'Vá em Configurações > Conta > Editar Perfil. Você pode alterar nome, email e telefone. Algumas alterações podem precisar de aprovação do RH.',
      },
      {
        'question': 'O que fazer se esquecer de bater o ponto?',
        'answer': 'Acesse Configurações > Solicitações e faça uma solicitação de ajuste de ponto. Seu gestor receberá a solicitação para aprovação.',
      },
      {
        'question': 'Como ativar notificações?',
        'answer': 'Vá em Configurações > Notificações e ative as notificações push. Certifique-se também que as notificações estão habilitadas nas configurações do seu telefone.',
      },
      {
        'question': 'O app funciona offline?',
        'answer': 'O app precisa de conexão com a internet para registrar pontos e sincronizar dados. Alguns dados podem ser visualizados offline, mas os registros requerem conexão.',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Central de Ajuda'),
        backgroundColor: Color(AppColors.primaryBlue),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(AppColors.primaryBlue).withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(AppColors.primaryBlue),
                      Color(AppColors.secondaryTeal),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.help_center_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Como podemos ajudar?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Encontre respostas para as perguntas mais comuns',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // FAQs
              ...faqs.map((faq) => _FAQCard(
                question: faq['question']!,
                answer: faq['answer']!,
              )),

              const SizedBox(height: 24),

              // Botão de contato
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Color(AppColors.primaryBlue).withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.contact_support_rounded,
                      size: 32,
                      color: Color(AppColors.primaryBlue),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Não encontrou o que procura?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Entre em contato com nosso suporte',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.white),
                                SizedBox(width: 8),
                                Text('Funcionalidade em desenvolvimento'),
                              ],
                            ),
                            backgroundColor: Color(AppColors.warningYellow),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(AppColors.primaryBlue),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Fale Conosco'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FAQCard extends StatefulWidget {
  final String question;
  final String answer;

  const _FAQCard({
    required this.question,
    required this.answer,
  });

  @override
  State<_FAQCard> createState() => __FAQCardState();
}

class __FAQCardState extends State<_FAQCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(AppColors.primaryBlue).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.help_outline,
              color: Color(AppColors.primaryBlue),
              size: 20,
            ),
          ),
          title: Text(
            widget.question,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          trailing: Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            color: Color(AppColors.primaryBlue),
          ),
          onExpansionChanged: (expanded) {
            setState(() => _isExpanded = expanded);
          },
          children: [
            Text(
              widget.answer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}