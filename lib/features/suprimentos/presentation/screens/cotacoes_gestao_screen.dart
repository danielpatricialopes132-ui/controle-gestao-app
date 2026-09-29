import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/providers/api_client_provider.dart';
import '../providers/suprimentos_provider.dart';

final listaCotacoesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/suprimentos/cotacoes');
  if (res is Map<String, dynamic> && res['success'] == true) {
    return res['data'] ?? [];
  }
  return [];
});

class CotacoesGestaoScreen extends ConsumerStatefulWidget {
  const CotacoesGestaoScreen({super.key});

  @override
  ConsumerState<CotacoesGestaoScreen> createState() => _CotacoesGestaoScreenState();
}

class _CotacoesGestaoScreenState extends ConsumerState<CotacoesGestaoScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  void _abrirModalNovaCotacao(BuildContext context) {
    final suprimentos = ref.read(suprimentosProvider);
    final tituloCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final List<Map<String, dynamic>> itensSelecionados = [];
    final List<String> fornecedoresIds = [];

    String? produtoSelecionadoId;
    final qtdCtrl = TextEditingController(text: '1');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Disparar Nova Cotação para Fornecedores',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF007A8D))),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tituloCtrl,
                    decoration: const InputDecoration(labelText: 'Título da Cotação * (Ex: Cotação de Cimento e Areia)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Observações / Instruções para os Fornecedores', border: OutlineInputBorder()),
                  ),
                  const Divider(height: 28),

                  // Seção Adicionar Produtos
                  const Text('Itens para Cotar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          value: produtoSelecionadoId,
                          decoration: const InputDecoration(labelText: 'Selecione o Insumo', border: OutlineInputBorder(), isDense: true),
                          items: suprimentos.produtos.map<DropdownMenuItem<String>>((p) {
                            return DropdownMenuItem<String>(
                              value: p['id'],
                              child: Text(p['nome'] ?? '', overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) => setModalState(() => produtoSelecionadoId = val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: qtdCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Qtd', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Color(0xFF007A8D)),
                        onPressed: () {
                          if (produtoSelecionadoId != null && qtdCtrl.text.isNotEmpty) {
                            final prod = suprimentos.produtos.firstWhere((p) => p['id'] == produtoSelecionadoId);
                            setModalState(() {
                              itensSelecionados.add({
                                'produtoId': produtoSelecionadoId,
                                'produtoNome': prod['nome'],
                                'quantidade': double.tryParse(qtdCtrl.text.replaceAll(',', '.')) ?? 1.0,
                              });
                              produtoSelecionadoId = null;
                              qtdCtrl.text = '1';
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  if (itensSelecionados.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...itensSelecionados.map((it) => Chip(
                          label: Text('${it['produtoNome']} (${it['quantidade']})'),
                          onDeleted: () {
                            setModalState(() => itensSelecionados.remove(it));
                          },
                        )),
                  ],
                  const Divider(height: 28),

                  // Fornecedores Convidados
                  const Text('Fornecedores Concorrentes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: suprimentos.fornecedores.map((f) {
                      final sel = fornecedoresIds.contains(f['id']);
                      return FilterChip(
                        label: Text(f['nome'] ?? ''),
                        selected: sel,
                        onSelected: (val) {
                          setModalState(() {
                            if (val) {
                              fornecedoresIds.add(f['id']);
                            } else {
                              fornecedoresIds.remove(f['id']);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: () async {
                      if (tituloCtrl.text.isEmpty || itensSelecionados.isEmpty || fornecedoresIds.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Preencha o título, adicione ao menos 1 item e selecione fornecedores.'), backgroundColor: Colors.red),
                        );
                        return;
                      }

                      try {
                        final api = ref.read(apiClientProvider);
                        final res = await api.post('/suprimentos/cotacoes', {
                          'titulo': tituloCtrl.text.trim(),
                          'descricao': descCtrl.text.trim(),
                          'itens': itensSelecionados,
                          'fornecedoresIds': fornecedoresIds,
                        });

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ref.invalidate(listaCotacoesProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cotação criada e links gerados com sucesso!'), backgroundColor: Colors.green),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Disparar Cotação Externa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007A8D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _copiarLink(BuildContext context, String link, String fornecedorNome) {
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link copiado! Envie por WhatsApp para $fornecedorNome:\n$link'),
        backgroundColor: Colors.teal,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cotacoesAsync = ref.watch(listaCotacoesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal de Cotações com Fornecedores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(listaCotacoesProvider),
          ),
        ],
      ),
      body: cotacoesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erro: $err', style: const TextStyle(color: Colors.red))),
        data: (cotacoes) {
          if (cotacoes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.request_quote_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('Nenhuma cotação externa aberta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Clique no botão abaixo para gerar links de cotação para fornecedores.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _abrirModalNovaCotacao(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Criar Primeira Cotação'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cotacoes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final cot = cotacoes[index];
              final List<dynamic> itens = cot['itens'] ?? [];
              final List<dynamic> respostas = cot['respostas'] ?? [];
              final dataCriacao = DateTime.tryParse(cot['criadoEm'] ?? '');

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              cot['titulo'] ?? '',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: cot['status'] == 'ABERTA' ? Colors.green.shade50 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              cot['status'] ?? 'ABERTA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: cot['status'] == 'ABERTA' ? Colors.green.shade800 : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (dataCriacao != null) ...[
                        const SizedBox(height: 4),
                        Text('Criada em: ${_dateFormat.format(dataCriacao)}  |  ${itens.length} itens solicitados',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                      const Divider(height: 24),

                      const Text('Respostas dos Fornecedores (Mapa Comparativo):',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 10),

                      ...respostas.map((r) {
                        final forn = r['fornecedor'] ?? {};
                        final respondido = r['respondido'] == true;
                        final token = r['tokenAcesso'];
                        final link = 'https://controle-gestao-ea7ad.web.app/cotacao-fornecedor?token=$token';

                        // Calcula total cotado pelo fornecedor
                        final List<dynamic> itensResp = r['itensResposta'] ?? [];
                        double totalProposta = 0;
                        for (final ir in itensResp) {
                          final preco = (ir['precoUnitario'] as num?)?.toDouble() ?? 0.0;
                          final cotItem = itens.firstWhere((it) => it['id'] == ir['cotacaoItemId'], orElse: () => null);
                          final qtd = (cotItem?['quantidade'] as num?)?.toDouble() ?? 1.0;
                          totalProposta += (preco * qtd);
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: respondido ? Colors.green.shade50 : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: respondido ? Colors.green.shade200 : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    forn['nome'] ?? 'Fornecedor',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    respondido
                                        ? 'Proposta Enviada: ${_currencyFormat.format(totalProposta)} (${r['prazoEntregaDias'] ?? 0} dias)'
                                        : 'Aguardando preenchimento pelo fornecedor',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: respondido ? Colors.green.shade800 : Colors.orange.shade800,
                                      fontWeight: respondido ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.share, size: 18),
                                    tooltip: 'Copiar link do portal',
                                    onPressed: () => _copiarLink(context, link, forn['nome'] ?? ''),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirModalNovaCotacao(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova Cotação Externa'),
      ),
    );
  }
}
