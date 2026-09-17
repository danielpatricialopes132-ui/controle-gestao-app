import 'package:flutter/material.dart';
import 'extrato_bancario_screen.dart';
import 'evolucao_financeira_screen.dart';
import 'gerencial_obra_screen.dart';
import 'frequencia_ponto_screen.dart';
import 'folha_pagamento_screen.dart';

class RelatoriosScreen extends StatelessWidget {
  const RelatoriosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet, size: 40, color: Colors.blue),
              title: const Text('Extrato Bancário', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Fluxo de caixa com saldo progressivo diário.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExtratoBancarioScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.show_chart, size: 40, color: Colors.green),
              title: const Text('Evolução Financeira da Obra', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Receitas, Despesas e Saldo agrupados por semana ou mês.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EvolucaoFinanceiraScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.pie_chart, size: 40, color: Colors.purple),
              title: const Text('DRE Gerencial Obra', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Comparativo Previsto x Realizado (Contrato Base e Adendos).'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GerencialObraScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_month, size: 40, color: Colors.orange),
              title: const Text('Frequência de Ponto', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Matriz de presença mensal (Trabalho, Viagem, Chuva, Falta).'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FrequenciaPontoScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.groups, size: 40, color: Colors.blueAccent),
              title: const Text('Folha de Pagamentos', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Cálculo de diárias, salários, vales e botão para gerar pagamentos.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FolhaPagamentoScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
