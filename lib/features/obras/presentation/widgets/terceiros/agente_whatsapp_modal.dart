import 'package:flutter/material.dart';

class AgenteWhatsappModal {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _AgenteWhatsappDialog(),
    );
  }
}

class _AgenteWhatsappDialog extends StatefulWidget {
  const _AgenteWhatsappDialog();

  @override
  State<_AgenteWhatsappDialog> createState() => _AgenteWhatsappDialogState();
}

class _AgenteWhatsappDialogState extends State<_AgenteWhatsappDialog> {
  final List<Map<String, dynamic>> _logs = [];
  bool _isProcessing = false;

  void _iniciarAgente() async {
    setState(() {
      _isProcessing = true;
      _logs.clear();
      _logs.add({'type': 'system', 'text': 'Iniciando Agente de Alinhamento Proativo (IA)...'});
    });

    await Future.delayed(const Duration(seconds: 1));
    setState(() => _logs.add({'type': 'system', 'text': 'Buscando fornecedores com prazo de entrega em até 3 dias...'}));

    await Future.delayed(const Duration(seconds: 2));
    setState(() => _logs.add({'type': 'info', 'text': 'Fornecedor encontrado: Marcenaria Móveis Finos (Previsão: 26/09/2026)'}));
    
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _logs.add({'type': 'bot', 'text': '[WhatsApp] Olá Marcenaria Móveis Finos! Sou a assistente virtual da obra. Confirmamos a montagem para daqui a 3 dias? Temos alguma pendência?'}));

    await Future.delayed(const Duration(seconds: 3));
    setState(() => _logs.add({'type': 'user', 'text': '[Marcenaria] Oi! Tudo certo por aqui. Pode confirmar para o dia 26 pela manhã.'}));

    await Future.delayed(const Duration(seconds: 1));
    setState(() => _logs.add({'type': 'system', 'text': 'Analisando resposta com Gemini Vision/Text...'}));
    
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _logs.add({'type': 'success', 'text': 'Confirmação registrada no Cronograma Físico! Status atualizado para PRONTO_ENTREGA.'}));

    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _logs.add({'type': 'system', 'text': 'Varredura concluída. 1 fornecedor contatado com sucesso.'});
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.smart_toy, color: Colors.teal),
          SizedBox(width: 8),
          Text('Agente de Alinhamento via WhatsApp'),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 400,
        child: Column(
          children: [
            const Text('A IA consulta automaticamente marmorarias, marcenarias e vidraçarias 3 dias antes do prazo de entrega para confirmar prontidão e evitar atrasos na obra.'),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (ctx, i) {
                    final log = _logs[i];
                    Color textColor;
                    IconData icon;
                    if (log['type'] == 'bot') {
                      textColor = Colors.greenAccent;
                      icon = Icons.support_agent;
                    } else if (log['type'] == 'user') {
                      textColor = Colors.blueAccent;
                      icon = Icons.person;
                    } else if (log['type'] == 'success') {
                      textColor = Colors.amberAccent;
                      icon = Icons.check_circle;
                    } else if (log['type'] == 'info') {
                      textColor = Colors.white;
                      icon = Icons.search;
                    } else {
                      textColor = Colors.grey.shade400;
                      icon = Icons.settings;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, color: textColor, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              log['text'],
                              style: TextStyle(color: textColor, fontSize: 13, fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
        ElevatedButton.icon(
          onPressed: _isProcessing ? null : _iniciarAgente,
          icon: _isProcessing 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
              : const Icon(Icons.play_arrow),
          label: Text(_isProcessing ? 'Processando...' : 'Iniciar Varredura'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
        ),
      ],
    );
  }
}
