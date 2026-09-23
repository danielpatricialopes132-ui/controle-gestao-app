import 'package:flutter/material.dart';

class RendimentoInsumosScreen extends StatefulWidget {
  const RendimentoInsumosScreen({super.key});

  @override
  State<RendimentoInsumosScreen> createState() => _RendimentoInsumosScreenState();
}

class _RendimentoInsumosScreenState extends State<RendimentoInsumosScreen> {
  final TextEditingController _areaController = TextEditingController();
  String _tipoServico = 'Alvenaria (Tijolo Baiano 9x19x19)';
  String _resultado = '';

  final Map<String, Map<String, double>> _rendimentos = {
    'Alvenaria (Tijolo Baiano 9x19x19)': {'Tijolos/m²': 25, 'Argamassa/m² (kg)': 15},
    'Pintura (Látex PVA - 2 demãos)': {'Tinta (L)/m²': 0.15, 'Massa Corrida (kg)/m²': 0.5},
    'Contrapiso (3cm de espessura)': {'Cimento (kg)/m²': 10, 'Areia (m³)/m²': 0.035},
    'Reboco (2cm de espessura)': {'Cimento (kg)/m²': 6, 'Areia (m³)/m²': 0.024, 'Cal (kg)/m²': 2},
  };

  void _calcular() {
    double area = double.tryParse(_areaController.text.replaceAll(',', '.')) ?? 0;
    if (area <= 0) {
      setState(() => _resultado = '');
      return;
    }

    final insumos = _rendimentos[_tipoServico]!;
    
    String res = 'Para ${area.toStringAsFixed(2)} m² de $_tipoServico:\n\n';
    insumos.forEach((key, valorPorM2) {
      double total = valorPorM2 * area;
      res += '- $key: ${total.toStringAsFixed(2)}\n';
    });

    setState(() {
      _resultado = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rendimento de Insumos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _tipoServico,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Tipo de Serviço', border: OutlineInputBorder()),
              items: _rendimentos.keys.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) {
                if (val != null) setState(() { _tipoServico = val; _calcular(); });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _areaController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Área Total (m²)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _calcular(),
            ),
            const SizedBox(height: 32),
            if (_resultado.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    const Text('Insumos Necessários', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    Text(
                      _resultado,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const Text(
                      '* Adicione margem de perda (normalmente 5% a 10%) nas suas compras.',
                      style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                    )
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}
