import 'package:flutter/material.dart';
import 'dart:math';

class CalculadoraFinanceiraScreen extends StatefulWidget {
  const CalculadoraFinanceiraScreen({super.key});

  @override
  State<CalculadoraFinanceiraScreen> createState() => _CalculadoraFinanceiraScreenState();
}

class _CalculadoraFinanceiraScreenState extends State<CalculadoraFinanceiraScreen> {
  int _selectedTab = 0; // 0: Markup, 1: Juros, 2: Horas Extras

  final _formKey = GlobalKey<FormState>();

  // Markup
  final _custoCtrl = TextEditingController();
  final _margemCtrl = TextEditingController();
  double _precoVenda = 0;

  // Juros
  final _capitalCtrl = TextEditingController();
  final _taxaCtrl = TextEditingController();
  final _tempoCtrl = TextEditingController();
  double _montante = 0;

  void _calcularMarkup() {
    final custo = double.tryParse(_custoCtrl.text) ?? 0;
    final margem = double.tryParse(_margemCtrl.text) ?? 0;
    if (margem >= 100) return;
    
    setState(() {
      _precoVenda = custo / (1 - (margem / 100));
    });
  }

  void _calcularJuros() {
    final capital = double.tryParse(_capitalCtrl.text) ?? 0;
    final taxa = double.tryParse(_taxaCtrl.text) ?? 0;
    final tempo = double.tryParse(_tempoCtrl.text) ?? 0;
    
    setState(() {
      _montante = capital * pow((1 + taxa / 100), tempo);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora Financeira'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Markup'), icon: Icon(Icons.sell)),
                ButtonSegment(value: 1, label: Text('Juros Compostos'), icon: Icon(Icons.trending_up)),
                ButtonSegment(value: 2, label: Text('Em breve...'), icon: Icon(Icons.more_horiz)),
              ],
              selected: {_selectedTab},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() {
                  _selectedTab = newSelection.first;
                });
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: _buildCurrentTab(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab() {
    if (_selectedTab == 0) {
      return _buildMarkup();
    } else if (_selectedTab == 1) {
      return _buildJuros();
    } else {
      return const Center(child: Text('Funcionalidade em desenvolvimento.'));
    }
  }

  Widget _buildMarkup() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _custoCtrl,
              decoration: const InputDecoration(labelText: 'Custo (R\$)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _margemCtrl,
              decoration: const InputDecoration(labelText: 'Margem Desejada (%)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _calcularMarkup,
              child: const Text('Calcular Preço de Venda'),
            ),
            const SizedBox(height: 24),
            if (_precoVenda > 0)
              Text(
                'Preço de Venda: R\$ ${_precoVenda.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildJuros() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _capitalCtrl,
              decoration: const InputDecoration(labelText: 'Capital Inicial (R\$)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _taxaCtrl,
              decoration: const InputDecoration(labelText: 'Taxa Mensal (%)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tempoCtrl,
              decoration: const InputDecoration(labelText: 'Período (Meses)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _calcularJuros,
              child: const Text('Calcular Montante'),
            ),
            const SizedBox(height: 24),
            if (_montante > 0)
              Text(
                'Montante Final: R\$ ${_montante.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }
}
