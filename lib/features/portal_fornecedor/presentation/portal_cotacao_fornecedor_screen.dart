import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/providers/api_client_provider.dart';

final portalCotacaoProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, token) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/portal/cotacao-externa?token=$token');
  if (res is Map<String, dynamic> && res['success'] == true) {
    return res['data'] ?? {};
  }
  return {};
});

class PortalCotacaoFornecedorScreen extends ConsumerStatefulWidget {
  final String token;

  const PortalCotacaoFornecedorScreen({super.key, required this.token});

  @override
  ConsumerState<PortalCotacaoFornecedorScreen> createState() => _PortalCotacaoFornecedorScreenState();
}

class _PortalCotacaoFornecedorScreenState extends ConsumerState<PortalCotacaoFornecedorScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _prazoEntregaController = TextEditingController();
  final _condicaoPagamentoController = TextEditingController(text: 'À vista / 30 dias');
  final _observacoesController = TextEditingController();

  final Map<String, TextEditingController> _precosControllers = {};
  final Map<String, TextEditingController> _marcasControllers = {};
  final Map<String, bool> _disponibilidade = {};

  bool _enviando = false;
  bool _enviadoSucesso = false;

  @override
  void dispose() {
    _prazoEntregaController.dispose();
    _condicaoPagamentoController.dispose();
    _observacoesController.dispose();
    for (final c in _precosControllers.values) {
      c.dispose();
    }
    for (final c in _marcasControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _inicializarLinhas(List<dynamic> itensCotacao, List<dynamic> itensResposta) {
    for (final item in itensCotacao) {
      final itemId = item['id'];
      if (!_precosControllers.containsKey(itemId)) {
        final resp = itensResposta.firstWhere(
          (r) => r['cotacaoItemId'] == itemId,
          orElse: () => null,
        );
        final precoInicial = resp != null ? NumberFormat('#,##0.00', 'pt_BR').format(resp['precoUnitario'] ?? 0) : '';
        final marcaInicial = resp?['marca'] ?? '';
        final dispInicial = resp?['disponivel'] ?? true;

        _precosControllers[itemId] = TextEditingController(text: precoInicial == '0,00' ? '' : precoInicial);
        _marcasControllers[itemId] = TextEditingController(text: marcaInicial);
        _disponibilidade[itemId] = dispInicial;
      }
    }
  }

  Future<void> _submeterCotacao(String token, List<dynamic> itensCotacao) async {
    setState(() => _enviando = true);
    try {
      final itensParaEnvio = itensCotacao.map((item) {
        final itemId = item['id'];
        final precoStr = _precosControllers[itemId]?.text.replaceAll('.', '').replaceAll(',', '.') ?? '0';
        final preco = double.tryParse(precoStr) ?? 0.0;
        final marca = _marcasControllers[itemId]?.text.trim() ?? '';
        final disp = _disponibilidade[itemId] ?? true;

        return {
          'cotacaoItemId': itemId,
          'precoUnitario': preco,
          'marca': marca,
          'disponivel': disp,
        };
      }).toList();

      final api = ref.read(apiClientProvider);
      final res = await api.post('/portal/cotacao-externa', {
        'token': token,
        'itensResposta': itensParaEnvio,
        'prazoEntregaDias': _prazoEntregaController.text.trim(),
        'condicaoPagamento': _condicaoPagamentoController.text.trim(),
        'observacoes': _observacoesController.text.trim(),
      });

      if (mounted) {
        if (res['success'] == true) {
          setState(() {
            _enviadoSucesso = true;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['error'] ?? 'Erro ao enviar proposta.'), backgroundColor: Colors.red),
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
        body: Center(
          child: Text('Link de cotação inválido. Verifique o link recebido por WhatsApp ou e-mail.'),
        ),
      );
    }

    final cotacaoAsync = ref.watch(portalCotacaoProvider(widget.token));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Portal de Cotações de Fornecedores'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: cotacaoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Erro ao carregar cotação: $err', style: const TextStyle(color: Colors.red)),
        ),
        data: (dados) {
          if (dados.isEmpty) {
            return const Center(
              child: Text('Cotação não encontrada ou encerrada.'),
            );
          }

          final fornecedor = dados['fornecedor'] ?? {};
          final cotacao = dados['cotacao'] ?? {};
          final tenant = cotacao['tenant'] ?? {};
          final List<dynamic> itens = cotacao['itens'] ?? [];
          final List<dynamic> itensResposta = dados['itensResposta'] ?? [];
          final bool jaRespondido = dados['respondido'] == true;

          _inicializarLinhas(itens, itensResposta);

          if (_enviadoSucesso || jaRespondido) {
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
                      child: Icon(Icons.check_circle, color: Colors.green, size: 48),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Cotação Enviada com Sucesso!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Obrigado, ${fornecedor['nome']}! Seus preços e condições foram recebidos pela equipe de Suprimentos da ${tenant['nome'] ?? 'Construtora'}.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card Empresa / Fornecedor
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tenant['nome'] ?? 'Construtora',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF007A8D)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text('Solicitação de Cotação: ${cotacao['titulo'] ?? ''}',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Fornecedor: ${fornecedor['nome']}',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                                ),
                              ),
                            ],
                          ),
                          if (cotacao['descricao'] != null && cotacao['descricao'].toString().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(cotacao['descricao'], style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tabela de Preenchimento de Itens
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
                          const Text(
                            'Preencha seus Preços Unitários e Marcas:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: itens.length,
                            separatorBuilder: (_, _) => const Divider(height: 24),
                            itemBuilder: (context, idx) {
                              final it = itens[idx];
                              final prod = it['produto'] ?? {};
                              final itId = it['id'];
                              final precoCtrl = _precosControllers[itId];
                              final marcaCtrl = _marcasControllers[itId];
                              final isDisp = _disponibilidade[itId] ?? true;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${idx + 1}. ${prod['nome'] ?? 'Item'} (${it['quantidade']} ${prod['unidadeMedida'] ?? 'un'})',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ),
                                      Checkbox(
                                        value: isDisp,
                                        onChanged: (val) {
                                          setState(() {
                                            _disponibilidade[itId] = val ?? true;
                                          });
                                        },
                                      ),
                                      Text(
                                        isDisp ? 'Disponível' : 'Indisponível',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDisp ? Colors.green.shade800 : Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: TextField(
                                          controller: precoCtrl,
                                          enabled: isDisp,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(
                                            labelText: 'Preço Unitário (R\$) *',
                                            prefixText: 'R\$ ',
                                            border: OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 3,
                                        child: TextField(
                                          controller: marcaCtrl,
                                          enabled: isDisp,
                                          decoration: const InputDecoration(
                                            labelText: 'Marca / Fabricante (Opcional)',
                                            border: OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Condições Comerciais (Prazo, Pagamento)
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
                          const Text(
                            'Condições Comerciais:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _prazoEntregaController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Prazo de Entrega (Dias corridos)',
                                    hintText: 'Ex: 5',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _condicaoPagamentoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Condição de Pagamento',
                                    hintText: 'Ex: 28 DDL / À vista',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _observacoesController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Observações Adicionais / Validade da Proposta',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botão Final de Submissão
                    ElevatedButton.icon(
                      onPressed: _enviando ? null : () => _submeterCotacao(widget.token, itens),
                      icon: _enviando
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send),
                      label: Text(
                        _enviando ? 'Enviando Cotação...' : 'Enviar Minha Proposta de Preços',
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
