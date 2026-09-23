import 'package:flutter/material.dart';

class CalculadoraTracosScreen extends StatefulWidget {
  const CalculadoraTracosScreen({super.key});

  @override
  State<CalculadoraTracosScreen> createState() => _CalculadoraTracosScreenState();
}

class _CalculadoraTracosScreenState extends State<CalculadoraTracosScreen> {
  final TextEditingController _cimentoController = TextEditingController(text: '1');
  
  String _tipoTraco = 'Concreto Estrutural (1:2:3)';
  String _resultado = '';

  final Map<String, List<double>> _proporcoes = {
    // [Cimento, Areia, Brita, Água (Litros por saco de 50kg)]
    'Concreto Estrutural (1:2:3)': [1, 2, 3, 25],
    'Concreto Magro (1:3:4)': [1, 3, 4, 30],
    'Argamassa Assentamento (1:3)': [1, 3, 0, 20],
    'Argamassa Reboco (1:4)': [1, 4, 0, 22],
  };

  void _calcular() {
    double qtdCimento = double.tryParse(_cimentoController.text.replaceAll(',', '.')) ?? 0;
    if (qtdCimento <= 0) {
      setState(() => _resultado = '');
      return;
    }

    final props = _proporcoes[_tipoTraco]!;
    final areia = qtdCimento * props[1];
    final brita = qtdCimento * props[2];
    final agua = qtdCimento * props[3];

    setState(() {
      _resultado = '''
Para ${qtdCimento.toStringAsFixed(1)} saco(s) de cimento (50kg):
- Areia: ${areia.toStringAsFixed(1)} lata(s) de 18L
${brita > 0 ? '- Brita: ${brita.toStringAsFixed(1)} lata(s) de 18L\n' : ''}- Água: ${agua.toStringAsFixed(1)} Litros
''';
    });
  }

  @override
  void initState() {
    super.initState();
    _calcular();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calculadora de Traços')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _tipoTraco,
              decoration: const InputDecoration(labelText: 'Tipo de Traço', border: OutlineInputBorder()),
              items: _proporcoes.keys.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) {
                if (val != null) setState(() { _tipoTraco = val; _calcular(); });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cimentoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Quantidade de Cimento (Sacos 50kg)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _calcular(),
            ),
            const SizedBox(height: 32),
            if (_resultado.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    const Text('Material Necessário', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    Text(
                      _resultado,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const Text(
                      '* Medida baseada em lata padrão de 18 Litros.\n* A quantidade de água pode variar pela umidade da areia.',
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
