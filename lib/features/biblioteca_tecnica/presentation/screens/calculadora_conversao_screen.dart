import 'package:flutter/material.dart';

class CalculadoraConversaoScreen extends StatefulWidget {
  const CalculadoraConversaoScreen({super.key});

  @override
  State<CalculadoraConversaoScreen> createState() => _CalculadoraConversaoScreenState();
}

class _CalculadoraConversaoScreenState extends State<CalculadoraConversaoScreen> {
  final TextEditingController _valorController = TextEditingController();
  
  String _tipoConversao = 'Comprimento';
  String _unidadeOrigem = 'Metros (m)';
  String _unidadeDestino = 'Centímetros (cm)';
  String _resultado = '';

  final Map<String, List<String>> _unidadesPorTipo = {
    'Comprimento': ['Milímetros (mm)', 'Centímetros (cm)', 'Metros (m)', 'Polegadas (in)', 'Pés (ft)'],
    'Massa': ['Gramas (g)', 'Quilogramas (kg)', 'Toneladas (t)', 'Libras (lb)'],
    'Volume': ['Mililitros (ml)', 'Litros (L)', 'Metros Cúbicos (m³)', 'Galões (gal)'],
    'Pressão (Resistência)': ['Pascal (Pa)', 'Megapascal (MPa)', 'kgf/cm²'],
  };

  void _calcularConversao() {
    if (_valorController.text.isEmpty) {
      setState(() => _resultado = '');
      return;
    }

    final double valor = double.tryParse(_valorController.text.replaceAll(',', '.')) ?? 0;
    double fatorOrigem = _obterFatorParaBase(_tipoConversao, _unidadeOrigem);
    double fatorDestino = _obterFatorParaBase(_tipoConversao, _unidadeDestino);

    // Converte para a base e depois para o destino
    double valorConvertido = (valor * fatorOrigem) / fatorDestino;

    setState(() {
      _resultado = '${valor.toStringAsFixed(2)} $_unidadeOrigem = ${valorConvertido.toStringAsFixed(4)} $_unidadeDestino';
    });
  }

  double _obterFatorParaBase(String tipo, String unidade) {
    // Base Comprimento: Metros
    if (tipo == 'Comprimento') {
      if (unidade == 'Milímetros (mm)') return 0.001;
      if (unidade == 'Centímetros (cm)') return 0.01;
      if (unidade == 'Metros (m)') return 1.0;
      if (unidade == 'Polegadas (in)') return 0.0254;
      if (unidade == 'Pés (ft)') return 0.3048;
    }
    // Base Massa: Quilogramas
    if (tipo == 'Massa') {
      if (unidade == 'Gramas (g)') return 0.001;
      if (unidade == 'Quilogramas (kg)') return 1.0;
      if (unidade == 'Toneladas (t)') return 1000.0;
      if (unidade == 'Libras (lb)') return 0.453592;
    }
    // Base Volume: Litros
    if (tipo == 'Volume') {
      if (unidade == 'Mililitros (ml)') return 0.001;
      if (unidade == 'Litros (L)') return 1.0;
      if (unidade == 'Metros Cúbicos (m³)') return 1000.0;
      if (unidade == 'Galões (gal)') return 3.78541;
    }
    // Base Pressão: Megapascal (MPa)
    if (tipo == 'Pressão (Resistência)') {
      if (unidade == 'Pascal (Pa)') return 0.000001;
      if (unidade == 'Megapascal (MPa)') return 1.0;
      if (unidade == 'kgf/cm²') return 0.0980665;
    }
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversor de Medidas')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _tipoConversao,
              decoration: const InputDecoration(labelText: 'Grandeza Física', border: OutlineInputBorder()),
              items: _unidadesPorTipo.keys.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _tipoConversao = val;
                    _unidadeOrigem = _unidadesPorTipo[val]!.first;
                    _unidadeDestino = _unidadesPorTipo[val]!.last;
                    _resultado = '';
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _unidadeOrigem,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'De', border: OutlineInputBorder()),
                    items: _unidadesPorTipo[_tipoConversao]!.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() { _unidadeOrigem = val; _calcularConversao(); });
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward),
                ),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _unidadeDestino,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Para', border: OutlineInputBorder()),
                    items: _unidadesPorTipo[_tipoConversao]!.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() { _unidadeDestino = val; _calcularConversao(); });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _valorController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor', border: OutlineInputBorder(), prefixIcon: Icon(Icons.edit)),
              onChanged: (_) => _calcularConversao(),
            ),
            const SizedBox(height: 32),
            if (_resultado.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  children: [
                    const Text('Resultado da Conversão', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      _resultado,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}
