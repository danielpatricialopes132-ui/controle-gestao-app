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

            _buildSection(
              context,
              icon: Icons.verified_user,
              title: '11. Portaria Condominial, Cautela de Retirada & Assinatura Digital',
              content: 'Segurança patrimonial, controle de acesso e formalização de entrega:\n'
              '- Liberação de Portaria & Acesso: Emissão de termos formais para o condomínio com relação nominal de montadores, RGs, CPFs, veículos e regras de serviço para entrega na guarita.\n'
              '- Cautela de Retirada de Materiais: Controle de itens que saem da obra para oficina (ex: cubas retiradas por marmorarias), com previsão de retorno e assinaturas digitais na tela do retirante e do encarregado.\n'
              '- Termo de Recebimento de Interiores: Coleta de assinatura digital do cliente na tela após auditoria do Punch List, gerando certidão PDF de entrega formal e aprovação.',
            ),

            _buildSection(
              context,
              icon: Icons.rocket_launch,
              title: '12. Portal do Montador, WhatsApp & Vistoria Antes/Depois (Fase 7)',
              content: 'Evoluções estratégicas de integração em tempo real e vistoria imersiva:\n'
              '- Portal do Montador / Terceiro: Link público seguro compartilhado via WhatsApp (sem necessidade de senha), onde o montador consulta seu crachá digital de liberação na guarita, regras do condomínio e faz upload de fotos da montagem direto da câmera do celular.\n'
              '- Notificações Automáticas via WhatsApp: Disparo com 1 clique de liberações de portaria e termos de cautela/retirada de peças para marmorarias e marcenarias com mensagens personalizadas.\n'
              '- Comparador Antes & Depois Interativo: Ferramenta visual com cortina slider para inspecionar a evolução dos ambientes antes e depois da montagem para anexo na Revista de Obra.',
            ),

            _buildSection(
              context,
              icon: Icons.psychology,
              title: '13. Super Auditor Contábil & Financeiro (Exclusivo MASTER)',
              content: 'Controladoria de alta precisão e conformidade contábil automatizada:\n'
              '- Score de Saúde Contábil (0 a 100%): Indicador em tempo real da qualidade dos lançamentos financeiros e da conformidade da DRE.\n'
              '- Enquadramento Inteligente no Plano de Contas: Detecção de anomalias (despesas de obras alocadas como administrativas, insumos de canteiro sem categoria ou categorias genéricas "Outros/Diversos") com recomendação automática e reclassificação em 1 clique.\n'
              '- Rastreamento de Duplicidades: Identifica pagamentos e repetições suspeitas de mesmo valor em intervalos curtos com opção de exclusão imediata.\n'
              '- Compliance Fiscal: Monitoramento de pagamentos efetuados sem recibo ou comprovante anexado.',
            ),

            _buildSection(
              context,
              icon: Icons.account_balance,
              title: '14. Conciliação Bancária Híbrida (.OFX e PDF com IA)',
              content: 'Batimento financeiro de alta precisão entre extratos reais e o Livro Caixa:\n'
              '- Suporte Dual: Importe arquivos bancários tradicionais .OFX ou extratos em formato PDF de qualquer instituição bancária (ex: C6 Bank, Itaú, Bradesco, etc.).\n'
              '- Leitura Inteligente com IA: O modelo multimodal Gemini analisa o PDF do extrato, extraindo linhas de débitos, créditos, PIX, tarifas e valores com precisão de centavos.\n'
              '- Conciliação em 1 Clique: O sistema localiza correspondências exatas por valor e tipo no Livro Caixa, permitindo vincular a movimentação e atualizar o status para PAGO com data real da compensação.',
            ),

            _buildSection(
              context,
              icon: Icons.sort,
              title: '15. Filtros e Ordenação Flexível do Fluxo de Caixa',
              content: 'Navegação rápida e produtiva em bases de lançamentos com alto volume:\n'
              '- Ordenação Padrão por Data: Por padrão, a listagem exibe sempre os lançamentos mais recentes primeiro (cronologia decrescente).\n'
              '- Seletor Interativo de Ordenação: Alterne instantaneamente o critério para Data, Valor ou Descrição, e utilize a seta (⬇️ / ⬆️) para alternar entre ordem decrescente ou crescente.\n'
              '- Filtros Combinados: Filtre por Tipo (Receitas/Despesas), Status (PAGO, PENDENTE, A CONFIRMAR), Conta Bancária Operacional (ex: C6), Obra e Seletor de Período personalizado com busca textual instantânea.',
            ),

            _buildSection(
              context,
              icon: Icons.forum_outlined,
              title: '16. Mensageria Interna Corporativa (Chat da Empresa)',
              content: 'Comunicação corporativa segura e integrada com as obras:\n'
              '- Conversas Diretas (1:1): Chat privativo entre membros da equipe com recibos de envio e leitura (✓✓).\n'
              '- Canais por Obra & Departamentos: Grupos de trabalho para troca de informações operacionais sem dispersão.\n'
              '- Notificações Push Instantâneas: Alertas via Firebase Cloud Messaging direto no smartphone.\n'
              '- Anexos e Mídias: Envio rápido de fotos de canteiro e documentos com armazenamento em nuvem.\n'
              '- Botão "Agendar Reunião": Atalho que abre o formulário de agenda já com os participantes do chat preenchidos.',
            ),

            _buildSection(
              context,
              icon: Icons.calendar_month,
              title: '17. Agenda de Compromissos & Agenda Inteligente com IA',
              content: 'Organização de tempo executiva com inteligência artificial:\n'
              '- Visão Dual (Profissional vs. Pessoal): Alterne entre compromissos corporativos e pessoais com privacidade estrita.\n'
              '- Convites Corporativos: Convide colegas de equipe para reuniões com botões de "Aceitar" ou "Recusar" e disparo de push notification.\n'
              '- Importação de Convites (.ICS / iCalendar): Importe convites recebidos por e-mail de Google Calendar, Outlook ou Apple Calendar com auto-upsert.\n'
              '- Agenda Inteligente com Gemini AI: Digite comandos em linguagem natural e a IA preenche o compromisso cruzando colaboradores e obras cadastradas.\n'
              '- Lembretes Automáticos: Alertas programados antes de cada compromisso para pontualidade nas entregas e vistorias.',
            ),
            _buildSection(
              context,
              icon: Icons.gavel,
              title: '18. Governança, Workflows & Alçadas de Aprovação',
              content: 'Controle corporativo de limites orçamentários e deliberações financeiras:\n'
              '- Central de Deliberações: Painel unificado para aprovação ou rejeição de Ordens de Compra e Medições de Empreiteiro com 1 clique.\n'
              '- Motor de Alçadas Parametrizável: Itens operacionais (até R\$ 5.000,00) podem ser deliberados pela Engenharia ou Financeiro; compras e medições de maior porte exigem autorização expressa da Diretoria ou perfil Master.\n'
              '- Trilha de Auditoria: Toda aprovação ou recusa registra carimbo de data/hora, perfil decisor e justificativa formal de compliance.\n'
              '- Automação com Contas a Pagar: A aprovação de uma Ordem ou Medição gera automaticamente a respectiva despesa no contas a pagar, com retenções de tributos (INSS, ISS, IRRF) calculadas.',
            ),
            _buildSection(
              context,
              icon: Icons.show_chart,
              title: '19. Cockpit Executivo & Curva S (EVM)',
              content: 'Visão executiva em tempo real com Curva S teórica vs. medição real:\n'
              '- Curva S de Avanço Físico: Comparativo gráfico entre o cronograma planejado e o avanço físico medido no canteiro.\n'
              '- Earned Value Management (EVM): Cálculo automático do CPI (Cost Performance Index) indicando se o custo real está dentro da meta ou em risco de estouro orçamentário.\n'
              '- Burn Rate Médio: Projeção de desembolso mensal e saldo orçamentário restante para término das obras.\n'
              '- Filtro Individual por Obra: Análise isolada de cada canteiro ou consolidação global da carteira de projetos.',
            ),
            _buildSection(
              context,
              icon: Icons.request_quote,
              title: '20. Portal de Cotações com Fornecedores Externos',
              content: 'Automação ágil do processo de suprimentos e concorrência de preços:\n'
              '- Criação de Cotação Multi-Fornecedores: Selecione os materiais do catálogo e marque os fornecedores convidados.\n'
              '- Link de Autoatendimento com Token Único: O fornecedor recebe um link direto (sem login complexo) para preencher preços, marcas, prazos e condições pelo celular ou computador.\n'
              '- Comparativo em Tempo Real: A equipe de compras visualiza o mapa comparativo de preços preenchido por cada fornecedor para tomada de decisão.',
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
