import 'package:flutter/material.dart';

import 'calculadora_tracos_screen.dart';
import 'tabela_eletrica_screen.dart';
import 'calculadora_conversao_screen.dart';
import 'rendimento_insumos_screen.dart';

class BibliotecaTecnicaScreen extends StatelessWidget {
  const BibliotecaTecnicaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca Técnica'),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildCard(
            context,
            'Calculadora de Traços',
            Icons.calculate,
            Colors.orange,
            const CalculadoraTracosScreen(),
          ),
          _buildCard(
            context,
            'Tabela Elétrica',
            Icons.electrical_services,
            Colors.blue,
            const TabelaEletricaScreen(),
          ),
          _buildCard(
            context,
            'Rendimento de Insumos',
            Icons.construction,
            Colors.green,
            const RendimentoInsumosScreen(),
          ),
          _buildCard(
            context,
            'Conversor de Medidas',
            Icons.sync,
            Colors.purple,
            const CalculadoraConversaoScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, Color color, Widget destination) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => destination),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
