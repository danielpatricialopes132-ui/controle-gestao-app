import 'package:flutter/material.dart';

class TabelaEletricaScreen extends StatelessWidget {
  const TabelaEletricaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tabela Elétrica (NBR 5410)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCardInfo(
              'Padrão de Cores de Fios',
              Icons.palette,
              Colors.blue,
              Column(
                children: [
                  _buildColorRow(Colors.lightBlue, 'Azul Claro', 'Condutor Neutro (Obrigatório)'),
                  const Divider(),
                  _buildColorRow(Colors.green, 'Verde ou Verde/Amarelo', 'Condutor de Proteção / Terra (Obrigatório)'),
                  const Divider(),
                  _buildColorRow(Colors.red, 'Vermelho, Preto, Marrom', 'Condutor Fase (Recomendado)'),
                  const Divider(),
                  _buildColorRow(Colors.amber, 'Amarelo, Branco, Cinza', 'Retorno (Interruptor para Lâmpada)'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildCardInfo(
              'Dimensionamento Básico (Cobre / PVC 70°C)',
              Icons.bolt,
              Colors.orange,
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.orange.shade50),
                  columns: const [
                    DataColumn(label: Text('Seção (mm²)')),
                    DataColumn(label: Text('Corrente Máx (A)')),
                    DataColumn(label: Text('Disjuntor Recomendado')),
                    DataColumn(label: Text('Uso Comum')),
                  ],
                  rows: const [
                    DataRow(cells: [DataCell(Text('1.5 mm²')), DataCell(Text('15.5 A')), DataCell(Text('10 A')), DataCell(Text('Iluminação'))]),
                    DataRow(cells: [DataCell(Text('2.5 mm²')), DataCell(Text('21.0 A')), DataCell(Text('16 A ou 20 A')), DataCell(Text('Tomadas de Uso Geral (TUG)'))]),
                    DataRow(cells: [DataCell(Text('4.0 mm²')), DataCell(Text('28.0 A')), DataCell(Text('25 A')), DataCell(Text('Ar-Condicionado / Torneira Elétrica'))]),
                    DataRow(cells: [DataCell(Text('6.0 mm²')), DataCell(Text('36.0 A')), DataCell(Text('32 A')), DataCell(Text('Chuveiro Elétrico (até 5500W/220V)'))]),
                    DataRow(cells: [DataCell(Text('10.0 mm²')), DataCell(Text('50.0 A')), DataCell(Text('40 A ou 50 A')), DataCell(Text('Chuveiro (7500W/220V) ou Ramal de Entrada'))]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardInfo(String title, IconData icon, Color color, Widget content) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildColorRow(Color color, String name, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(desc, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
