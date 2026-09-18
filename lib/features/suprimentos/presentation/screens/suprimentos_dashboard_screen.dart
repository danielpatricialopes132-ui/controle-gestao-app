import 'package:flutter/material.dart';
import 'produtos_screen.dart';
import 'fornecedores_screen.dart';
import 'ordens_compra_screen.dart';
import 'estoque_screen.dart';

class SuprimentosDashboardScreen extends StatelessWidget {
  const SuprimentosDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Módulo de Suprimentos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildCard(
              context,
              title: 'Produtos / Catálogo',
              icon: Icons.inventory_2,
              color: Colors.blue,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProdutosScreen()));
              },
            ),
            _buildCard(
              context,
              title: 'Fornecedores',
              icon: Icons.local_shipping,
              color: Colors.orange,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FornecedoresScreen()));
              },
            ),
            _buildCard(
              context,
              title: 'Ordens de Compra',
              icon: Icons.receipt_long,
              color: Colors.green,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdensCompraScreen()));
              },
            ),
            _buildCard(
              context,
              title: 'Estoque Local',
              icon: Icons.store,
              color: Colors.purple,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EstoqueScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              radius: 30,
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
