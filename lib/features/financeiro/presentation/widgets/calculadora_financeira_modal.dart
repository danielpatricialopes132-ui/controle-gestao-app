import 'package:flutter/material.dart';

class CalculadoraFinanceiraModal extends StatefulWidget {
  const CalculadoraFinanceiraModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CalculadoraFinanceiraModal(),
    );
  }

  @override
  State<CalculadoraFinanceiraModal> createState() => _CalculadoraFinanceiraModalState();
}

class _CalculadoraFinanceiraModalState extends State<CalculadoraFinanceiraModal> {
  final TextEditingController _valorBaseController = TextEditingController();
  final TextEditingController _percentualController = TextEditingController();
  
  double _resultado = 0.0;
  String _operacao = 'ACRESCIMO'; // ACRESCIMO, DESCONTO, PORCENTAGEM_SIMPLES

  void _calcular() {
    final valor = double.tryParse(_valorBaseController.text.replaceAll(',', '.')) ?? 0.0;
    final perc = double.tryParse(_percentualController.text.replaceAll(',', '.')) ?? 0.0;

    setState(() {
      if (_operacao == 'ACRESCIMO') {
        _resultado = valor + (valor * (perc / 100));
      } else if (_operacao == 'DESCONTO') {
        _resultado = valor - (valor * (perc / 100));
      } else {
        _resultado = (valor * (perc / 100)); // Só o valor da porcentagem
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Calculadora Rápida',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'ACRESCIMO', label: Text('Juros/Acresc.')),
                ButtonSegment(value: 'DESCONTO', label: Text('Desconto')),
                ButtonSegment(value: 'PORCENTAGEM_SIMPLES', label: Text('Apenas %')),
              ],
              selected: {_operacao},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _operacao = newSelection.first;
                });
                _calcular();
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _valorBaseController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Valor Base (R\$)',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    onChanged: (_) => _calcular(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _percentualController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Percentual (%)',
                      prefixIcon: Icon(Icons.percent),
                    ),
                    onChanged: (_) => _calcular(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  const Text('Resultado', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(
                    'R\$ ${_resultado.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 32, 
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
