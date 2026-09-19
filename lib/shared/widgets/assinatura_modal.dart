import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class AssinaturaModal extends StatefulWidget {
  final String titulo;

  const AssinaturaModal({Key? key, this.titulo = 'Assinatura Eletrônica'}) : super(key: key);

  @override
  State<AssinaturaModal> createState() => _AssinaturaModalState();

  /// Função auxiliar para exibir o modal
  static Future<Uint8List?> mostrar(BuildContext context, {String titulo = 'Assinatura Eletrônica'}) {
    return showDialog<Uint8List?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AssinaturaModal(titulo: titulo),
    );
  }
}

class _AssinaturaModalState extends State<AssinaturaModal> {
  late SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.transparent,
      onDrawStart: () => print('Iniciou assinatura'),
      onDrawEnd: () => print('Terminou assinatura'),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_controller.isNotEmpty) {
      final bytes = await _controller.toPngBytes();
      if (mounted) {
        Navigator.of(context).pop(bytes);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, assine no campo acima.')),
        );
      }
    }
  }

  void _limpar() {
    _controller.clear();
  }

  void _cancelar() {
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.titulo,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Desenhe sua assinatura no quadro abaixo:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Signature(
                  controller: _controller,
                  height: 250,
                  backgroundColor: Colors.grey.shade50,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _cancelar,
                  icon: const Icon(Icons.close),
                  label: const Text('Cancelar'),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _limpar,
                      icon: const Icon(Icons.clear),
                      label: const Text('Limpar'),
                      style: TextButton.styleFrom(foregroundColor: Colors.orange),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _salvar,
                      icon: const Icon(Icons.check),
                      label: const Text('Confirmar'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
