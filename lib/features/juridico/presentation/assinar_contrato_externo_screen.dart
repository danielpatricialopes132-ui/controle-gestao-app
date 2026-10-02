import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';
import '../../../../shared/providers/api_client_provider.dart';

final documentoAssinaturaProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, token) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/portal/assinar-documento?token=$token');
  if (res is Map<String, dynamic> && res['success'] == true) {
    return res['data'] ?? {};
  }
  return {};
});

class AssinarContratoExternoScreen extends ConsumerStatefulWidget {
  final String token;

  const AssinarContratoExternoScreen({super.key, required this.token});

  @override
  ConsumerState<AssinarContratoExternoScreen> createState() => _AssinarContratoExternoScreenState();
}

class _AssinarContratoExternoScreenState extends ConsumerState<AssinarContratoExternoScreen> {
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final _otpController = TextEditingController();
  final SignatureController _sigController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  bool _concordaTermos = false;
  bool _enviando = false;
  Map<String, dynamic>? _comprovanteSucesso;

  @override
  void dispose() {
    _otpController.dispose();
    _sigController.dispose();
    super.dispose();
  }

  Future<void> _concluirAssinatura(String token) async {
    if (_sigController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, desenhe sua assinatura na tela.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!_concordaTermos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você deve aceitar os termos de assinatura eletrônica.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _enviando = true);
    try {
      final bytes = await _sigController.toPngBytes();
      if (bytes == null) throw Exception('Erro ao capturar assinatura.');

      final base64Image = 'data:image/png;base64,${base64Encode(bytes)}';

      final api = ref.read(apiClientProvider);
      final res = await api.post('/portal/assinar-documento', {
        'token': token,
        'codigoOtp': _otpController.text.trim(),
        'assinaturaBase64': base64Image,
      });

      if (mounted) {
        if (res['success'] == true) {
          setState(() {
            _comprovanteSucesso = res['data'];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['error'] ?? 'Falha ao registrar assinatura.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.token.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Link de assinatura inválido ou não informado.')),
      );
    }

    final docAsync = ref.watch(documentoAssinaturaProvider(widget.token));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Assinatura Eletrônica de Contratos'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: docAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erro: $err', style: const TextStyle(color: Colors.red))),
        data: (doc) {
          if (doc.isEmpty) {
            return const Center(child: Text('Documento não encontrado ou link expirado.'));
          }

          final jaAssinado = doc['status'] == 'ASSINADO' || _comprovanteSucesso != null;

          if (jaAssinado) {
            final hash = _comprovanteSucesso?['hashSha256'] ?? 'REGISTRADO_NA_BLOCKCHAIN';
            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 550),
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: Color(0xFFE8F5E9),
                      child: Icon(Icons.verified, color: Colors.green, size: 48),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Documento Assinado com Sucesso!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Signatário: ${doc['nomeSignatario']}\nCPF/CNPJ: ${doc['cpfCnpjSignatario'] ?? 'Não informado'}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const Divider(height: 28),
                    const Text('Carimbo de Integridade Criptográfica (Lei 14.063/2020):',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    SelectableText(
                      hash,
                      style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cabeçalho Documento
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                doc['empresaNome'] ?? 'Construtora',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF007A8D)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  doc['tipoContrato'] ?? 'CONTRATO',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(doc['tituloDocumento'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Signatário Destinatário: ${doc['nomeSignatario']}',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Área de Rubrica / Assinatura
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Desenhe sua Assinatura / Rubrica:',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              TextButton.icon(
                                onPressed: () => _sigController.clear(),
                                icon: const Icon(Icons.clear, size: 16),
                                label: const Text('Limpar', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              border: Border.all(color: Colors.blueGrey.shade200, width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Signature(
                                controller: _sigController,
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('Use o dedo ou a caneta óptica para assinar no quadro acima.',
                              style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Dupla Autenticação (OTP) se houver
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Código de Validação (OTP - 6 dígitos):',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('Insira o código de segurança enviado por WhatsApp ou E-mail para validação jurídica.',
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Código OTP (Opcional se validado via token)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Termos legais
                    Row(
                      children: [
                        Checkbox(
                          value: _concordaTermos,
                          onChanged: (val) => setState(() => _concordaTermos = val ?? false),
                        ),
                        const Expanded(
                          child: Text(
                            'Declaro que li e concordo com os termos do contrato, autenticando minha assinatura eletrônica nos termos da Lei Federal nº 14.063/2020.',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Botão Assinar
                    ElevatedButton.icon(
                      onPressed: _enviando ? null : () => _concluirAssinatura(widget.token),
                      icon: _enviando
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        _enviando ? 'Autenticando Documento...' : 'Confirmar e Assinar Eletronicamente',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007A8D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
