import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../ai/presentation/gemini_chat_widget.dart';

class ManualScreen extends ConsumerWidget {
  const ManualScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(appUserProvider);
    final ehMaster = userData?['role'] == 'MASTER';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual do Usuário & Central de Ajuda'),
        actions: [
          if (ehMaster)
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const GeminiChatDialog(),
                );
              },
              icon: const Icon(Icons.auto_awesome, color: Colors.amber),
              label: const Text('Ajuda IA Master', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ERP DPG Construtoras & Obras', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 8),
            const Text('Manual Operacional Oficial atualizado com os recursos da Fase 3: Empreiteiros, Subcontratação, Inteligência de Preços e Auditoria.'),
            const SizedBox(height: 24),

            if (ehMaster)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.indigo.shade800, Colors.blue.shade900]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.amber, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Consultor IA Especialista para <MASTER>', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          const Text('Tire dúvidas instantâneas sobre deduções tributárias (Art. 31 Lei 8.212/91), adendos contratuais, compliance de canteiro e auditoria.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const GeminiChatDialog(),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black87),
                      child: const Text('Abrir IA'),
                    ),
                  ],
                ),
              ),
            
            _buildSection(
              context,
              icon: Icons.dashboard,
              title: '1. Dashboard e Multi-Tenant',
              content: 'Visão executiva em tempo real com saldo em caixa, despesas a vencer e status das obras.\n'
              '- Cada empresa (Tenant) possui sua identidade própria: logomarca customizada e plano de categorias financeiras configuráveis.\n'
              '- O perfil MASTER pode navegar livremente entre as empresas pelo seletor de topo.',
            ),
            
            _buildSection(
              context,
              icon: Icons.handshake,
              title: '2. Gestão de Empreiteiros, Subcontratação & Contratos',
              content: 'Módulo completo para controle de terceiros e subcontratados no canteiro:\n'
              '- Contrato Inicial & Adendos: Registre o contrato inicial com objeto, prazos e taxas pactuadas de retenção (INSS, ISS, IRRF). Registre Adendos de Acréscimo de Valor ou Prorrogação de Prazo, mantendo o saldo contratual atualizado e a trilha legal preservada.\n'
              '- Subcontratação Hierárquica: Cadastre Empreiteiros Principais e vincule suas empresas Subcontratadas.\n'
              '- Dedução Legal de Subcontratados (Art. 31 da Lei 8.212/91): Na medição do Empreiteiro Principal, deduza os valores já retidos e recolhidos de subempreiteiros para evitar a bitributação de INSS.\n'
              '- Integração Financeira: Cada medição registrada e aprovada cria automaticamente a respectiva despesa no módulo Contas a Pagar.',
            ),

            _buildSection(
              context,
              icon: Icons.people,
              title: '3. RH, Presença no Canteiro & Diário de Ponto',
              content: 'Rastreabilidade completa de equipe própria e terceiros:\n'
              '- Vínculo Trabalhista: No cadastro do colaborador, defina se é Equipe Própria ou Terceirizado, vinculando-o ao Empreiteiro Principal ou Subcontratado.\n'
              '- Ponto Administrativo: Lançamento diário de presenças no canteiro (Trabalho, Viagem, Chuva, Falta) com badges visuais que identificam terceiros diretos e subcontratados.\n'
              '- Mitigação de Riscos: A comprovação rigorosa da presença protege a construtora de passivos de responsabilidade subsidiária trabalhista (Súmula 331 TST).',
            ),
            
            _buildSection(
              context,
              icon: Icons.price_check,
              title: '4. Suprimentos & Inteligência de Preços de Insumos',
              content: 'Controle de custos unitários e comparação de mercado:\n'
              '- Histórico de Preços: Registro do valor unitário de cada compra de insumo (cimento, areia, aço, brita, etc.).\n'
              '- Indicadores Analíticos: Custo Médio Ponderado, Menor e Maior Preço Histórico e Ranking comparativo de fornecedores mais vantajosos.\n'
              '- Alerta de Sobrepreço (>10%): Ao criar uma Ordem de Compra com valor unitário mais de 10% superior ao histórico, o sistema exibe alerta preventivo para negociação.',
            ),

            _buildSection(
              context,
              icon: Icons.auto_stories,
              title: '5. Revista da Obra (Semanal & Mensal) vs Diário Técnico (RDO)',
              content: 'Abordagem dual inteligente para comunicação e engenharia:\n'
              '- Revista Executiva da Obra: Edições em formato Semanal ou Mensal com capa premium, carta do engenheiro, infográficos de clima e avanço, storytelling por ambientes e metas do próximo ciclo (Lookahead). Exportação instantânea em PDF e compartilhamento no WhatsApp.\n'
              '- Diário Técnico de Obra (RDO): Registro diário com efetivo nominal de trabalhadores próprios e terceiros, condições do tempo, fotos e campos para assinatura do engenheiro.',
            ),

            _buildSection(
              context,
              icon: Icons.architecture,
              title: '6. Gerenciamento de Obras & Coordenação de Terceiros (Fase 6)',
              content: 'Para empresas que atuam na coordenação de reformas e obras de alto padrão:\n'
              '- Acompanhamento de empresas contratadas pelo cliente (marcenaria, mármores, automação, ar-condicionado, esquadrias).\n'
              '- Vistorias de entrega e Punch List (registro de pendências com fotos e prazos).\n'
              '- Boletins de coordenação orientando a liberação de pagamentos aos terceiros.',
            ),

            _buildSection(
              context,
              icon: Icons.security,
              title: '7. Auditoria Detalhada Imutável (Logs)',
              content: 'Governança e transparência para prestação de contas:\n'
              '- Tabela de auditoria exclusiva para Administradores mostrando: Quem realizou a ação, O Quê foi alterado (dados anteriores x dados novos), Em Qual Data/Hora e em Qual Módulo.\n'
              '- Rastreamento completo de edições e exclusões em Transações Financeiras e Ordens de Compra.',
            ),
            
            _buildSection(
              context,
              icon: Icons.school,
              title: '8. Treinamento & Apostila Oficial do Sistema',
              content: 'Ambiente de capacitação prática disponível na empresa TESTE S/A.\n'
              '- Consulte a apostila completa compartilhável MANUAL_CURSO_TREINAMENTO.md na raiz do sistema para roteiros passo a passo de treinamento de novos colaboradores.',
            ),

            _buildSection(
              context,
              icon: Icons.auto_stories,
              title: '9. Relatórios de Obra: Revista Executiva vs RDO Técnico',
              content: 'Comunicação executiva e rigor técnico lado a lado:\n'
              '- Revista da Obra (Semanal / Mensal): Publicação diagramada em alta resolução com editorial do engenheiro, infográficos de clima (sol vs chuva), avanço físico e fotos por ambiente.\n'
              '- Diário Técnico (RDO): Histórico nominal diário do efetivo no canteiro (CLT, diaristas, empreiteiros e subcontratados) com documento formal para assinatura técnica.',
            ),

            _buildSection(
              context,
              icon: Icons.architecture,
              title: '10. Coordenação de Terceiros & Mapa Semanal (S-T-Q-Q-S-S-D)',
              content: 'Gestão de obras de interiores e empresas contratadas pelo cliente:\n'
              '- Rastreamento do ciclo de vida: Contratado ➔ Medição In Loco ➔ Fabricação ➔ Pronto Entrega ➔ Montagem ➔ Entregue e Aprovado.\n'
              '- Mapa Semanal de Visitas (S • T • Q • Q • S • S • D): Registro presencial com dias da semana e motivo (medição, montagem, vistoria), impresso automaticamente no Boletim Semanal da Obra.\n'
              '- Vistorias de Recebimento & Punch List: Gestão de não-conformidades com prazos de resolução.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required IconData icon, required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Card(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.indigo, size: 26),
                  const SizedBox(width: 12),
                  Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                ],
              ),
              const SizedBox(height: 12),
              Text(content, style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
}
