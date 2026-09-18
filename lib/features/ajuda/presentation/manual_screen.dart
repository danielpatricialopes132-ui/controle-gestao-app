import 'package:flutter/material.dart';

class ManualScreen extends StatelessWidget {
  const ManualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual do Usuário & Guia Rápido'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bem-vindo ao ERP DPG Construtoras & Obras', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            const SizedBox(height: 16),
            const Text('Este sistema foi desenvolvido para facilitar a gestão financeira, de obras e de recursos humanos da sua empresa. Abaixo, você encontrará um guia rápido das principais funcionalidades.'),
            const SizedBox(height: 32),
            
            _buildSection(
              context,
              icon: Icons.dashboard,
              title: '1. Dashboard (Início)',
              content: 'O painel inicial exibe o saldo atual da empresa, contas a pagar por vencimento, status das obras e as últimas movimentações. Caso você seja um Administrador Master, poderá alternar entre as empresas no topo da tela.',
            ),
            
            _buildSection(
              context,
              icon: Icons.construction,
              title: '2. Gestão de Obras',
              content: 'Nesta seção você cadastra as obras ativas e inativas. Pode acompanhar o progresso geral e o status de cada fase (como Escavação, Alvenaria, Hidráulica). O progresso pode ser editado na visualização detalhada de cada obra.',
            ),
            
            _buildSection(
              context,
              icon: Icons.account_balance_wallet,
              title: '3. Financeiro',
              content: 'Aba dedicada ao controle de receitas, despesas e vales dos funcionários.\n'
              '- Lançar Transação: Clique no botão flutuante para adicionar uma receita ou despesa. Selecione a categoria correta para facilitar os relatórios.\n'
              '- Validação: Toda conta tem status PAGO ou PENDENTE.\n'
              '- Configuração Contábil: Cadastre novas categorias no botão de engrenagem.',
            ),
            
            _buildSection(
              context,
              icon: Icons.people,
              title: '4. Recursos Humanos e Empreiteiros',
              content: 'Aqui você gerencia sua equipe (CLT, Diaristas e Empreiteiros PJ).\n'
              '- Apontamento Simplificado: Gere a folha do diário de obra de forma rápida e em lote para todos os presentes na obra.\n'
              '- Vales e Adiantamentos: Lance adiantamentos que já geram uma Despesa automática no seu fluxo de caixa.\n'
              '- Equipe: Cadastro rápido unificado, com salários e chaves PIX.',
            ),
            
            _buildSection(
              context,
              icon: Icons.inventory_2,
              title: '5. Suprimentos (Compras e Estoque)',
              content: 'Gestão de materiais e cadeia de suprimentos da empresa.\n'
              '- Catálogo de Produtos: Cadastre os insumos com suas unidades de medida e preços base.\n'
              '- Fornecedores: Base de dados dos seus parceiros de negócios.\n'
              '- Ordens de Compra: Crie e aprove ordens de materiais para as obras. Ao marcar uma ordem como "ENTREGUE", o sistema provisiona automaticamente a despesa no módulo Financeiro da Obra.',
            ),
            
            _buildSection(
              context,
              icon: Icons.handshake,
              title: '6. Vendas e CRM',
              content: 'O módulo de Vendas ajuda a prospectar clientes e fechar negócios de forma automatizada:\n'
              '- Clientes: Cadastre dados de contato e faturamento.\n'
              '- Orçamentos: Monte propostas detalhadas. Se o cliente aprovar, o sistema cria a "Obra" automaticamente!\n'
              '- Faturas em PDF: Gere orçamentos profissionais e faturas em PDF em 1 clique.',
            ),

            _buildSection(
              context,
              icon: Icons.directions_car,
              title: '7. Frota e Máquinas',
              content: 'Controle os ativos pesados e veículos da sua construtora.\n'
              '- Equipamentos: Cadastro de máquinas e custo diário padrão.\n'
              '- Alocação: Envie as máquinas para o canteiro e controle o tempo de estadia (gerando custo gerencial automático).\n'
              '- Manutenções Preventivas: Agende por data a próxima troca de óleo ou revisão da máquina.',
            ),
            
            _buildSection(
              context,
              icon: Icons.picture_as_pdf,
              title: '8. Relatórios e Exportações em PDF',
              content: 'Geração de demonstrativos financeiros (DRE), relatórios de obras, saldos e ponto dos colaboradores.\n'
              '- PDFs Corporativos: Você pode exportar seu DRE, Fluxo de Caixa, RDO (Diário de Obra) com fotos e Extrato do Empreiteiro em PDF com um clique, prontos para enviar via WhatsApp.',
            ),
            
            _buildSection(
              context,
              icon: Icons.auto_awesome,
              title: '9. Assistente Virtual (IA)',
              content: 'Exclusivo para perfis MASTER, o botão flutuante abre o Assistente de Inteligência Artificial para tirar dúvidas rápidas sobre lançamentos contábeis ou análise de dados.',
            ),

            _buildSection(
              context,
              icon: Icons.wifi_off,
              title: '10. Modo Offline e PWA / Mobile',
              content: 'O sistema funciona sem internet?\n'
              'Sim! No Android ou pelo PWA instalado, você pode apontar horas, bater fotos de diário de obras, e dar baixa no estoque em canteiros sem sinal (Offline-First). Os dados serão enviados automaticamente assim que o celular reconectar ao 4G ou Wi-Fi.\n\n'
              'Como instalar no celular?\n'
              'No navegador, busque a opção "Adicionar à Tela Inicial" (PWA) ou baixe o APK para Android para ter acesso a todos os recursos offline.',
            ),
            
            _buildSection(
              context,
              icon: Icons.security,
              title: '11. Segurança e Perfis (RBAC)',
              content: 'Controle de acesso granular baseado em funções (Role-Based Access Control).\n'
              '- Perfis como ALMOXARIFE não têm acesso aos módulos financeiros e de RH.\n'
              '- O sistema conta com uma Trilha de Auditoria que registra aprovações de ordens de compra e pagamentos.',
            ),
            
            _buildSection(
              context,
              icon: Icons.school,
              title: '11. Ambiente de Treinamento (TESTE S/A)',
              content: 'Precisa treinar um novo funcionário sem afetar os dados reais da sua empresa? Utilize o ambiente de testes.\n'
              '- Acesse com o login: aluno@testesa.com.br\n'
              '- O sistema carregará a empresa fictícia "TESTE S/A - Ambiente de Curso". Nela, você pode cadastrar obras, lançar notas e testar todo o ERP sem medo.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required IconData icon, required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.blueAccent, size: 28),
                  const SizedBox(width: 12),
                  Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                ],
              ),
              const SizedBox(height: 12),
              Text(content, style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
}
