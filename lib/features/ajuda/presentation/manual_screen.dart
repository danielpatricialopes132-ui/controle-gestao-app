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
            Text('Bem-vindo ao ERP Jhoston Tec', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
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
              title: '4. Recursos Humanos (RH)',
              content: 'Aqui você gerencia seus colaboradores.\n'
              '- Controle de Ponto: Lançamento de escalas de trabalho e validação diária. Você também pode importar a escala pelo WhatsApp colando o texto na ferramenta de importação.\n'
              '- Cadastro: Adicione informações como função, salário base e contatos.',
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
              icon: Icons.picture_as_pdf,
              title: '7. Relatórios',
              content: 'Geração de demonstrativos financeiros (DRE), relatórios de obras, saldos e ponto dos colaboradores. Os relatórios podem ser impressos ou enviados via WhatsApp.',
            ),
            
            _buildSection(
              context,
              icon: Icons.auto_awesome,
              title: '8. Assistente Virtual (IA)',
              content: 'Exclusivo para perfis MASTER, o botão flutuante abre o Assistente de Inteligência Artificial para tirar dúvidas rápidas sobre lançamentos contábeis ou análise de dados.',
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
