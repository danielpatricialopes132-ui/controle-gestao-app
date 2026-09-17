import 'package:flutter/material.dart';

class ValeModal extends StatefulWidget {
  const ValeModal({super.key});

  @override
  State<ValeModal> createState() => _ValeModalState();

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const ValeModal(),
      ),
    );
  }
}

class _ValeModalState extends State<ValeModal> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  final _descricaoController = TextEditingController();
  
  String? _funcionarioSelecionado;
  String _tipo = 'SALARIAL';
  bool _temValeAberto = false; // Simulando a validação do Alerta

  void _verificarValesEmAberto(String? funcId) {
    // TODO: Bater na API e checar se o funcionarioId tem vales ABERTOS
    // Simulando: se escolher o 1, avisa.
    setState(() {
      _temValeAberto = (funcId == '1');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Lançar Novo Vale (Adiantamento)',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Dropdown de Funcionários
            DropdownButtonFormField<String>(
              value: _funcionarioSelecionado,
              decoration: const InputDecoration(
                labelText: 'Selecione o Funcionário',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: '1', child: Text('João Silva (C/ Vale em Aberto)')),
                DropdownMenuItem(value: '2', child: Text('Maria Souza')),
              ],
              onChanged: (val) {
                setState(() => _funcionarioSelecionado = val);
                _verificarValesEmAberto(val);
              },
              validator: (val) => val == null ? 'Obrigatório selecionar o funcionário' : null,
            ),
            
            if (_temValeAberto) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Atenção: Este funcionário possui vales antigos ainda não descontados na folha.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _tipo,
              decoration: const InputDecoration(
                labelText: 'Tipo de Vale',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'SALARIAL', child: Text('Adiantamento Salarial')),
                DropdownMenuItem(value: 'VIAGEM', child: Text('Adiantamento Viagem/Despesa')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _tipo = val);
              },
            ),
            
            const SizedBox(height: 16),
            TextFormField(
              controller: _valorController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Valor do Vale (R\$)',
                border: OutlineInputBorder(),
              ),
              validator: (val) => (val == null || val.isEmpty) ? 'Obrigatório' : null,
            ),

            const SizedBox(height: 16),
            TextFormField(
              controller: _descricaoController,
              decoration: const InputDecoration(
                labelText: 'Descrição / Motivo (Opcional)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // TODO: Enviar POST /api/financeiro/vales
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vale registrado com sucesso! (Não foi abatido do caixa ainda)')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Confirmar Vale'),
            ),
          ],
        ),
      ),
    );
  }
}
