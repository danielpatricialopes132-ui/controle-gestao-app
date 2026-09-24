import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/financeiro_provider.dart';
import '../../rh/providers/rh_provider.dart' hide valesProvider;
import '../../auth/providers/auth_provider.dart';
import 'transacao_modal.dart';
import 'vale_modal.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:xml/xml.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'widgets/calculadora_financeira_modal.dart';
import 'screens/ofx_import_screen.dart';
import 'screens/previsao_ia_screen.dart';
import 'screens/importacao_csv_screen.dart';
import 'screens/aprovacoes_pendentes_screen.dart';
import 'screens/auditoria_financeira_screen.dart';

class FinanceiroScreen extends ConsumerStatefulWidget {
  const FinanceiroScreen({super.key});

  @override
  ConsumerState<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends ConsumerState<FinanceiroScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(appUserProvider);
      if (user != null && user['role'] == 'CLIENTE') {
        context.go('/portal-cliente');
      }
    });
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financeiro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Ajuda',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Ajuda - Financeiro'),
                  content: const SingleChildScrollView(
                    child: Text(
                      'Bem-vindo ao módulo Financeiro!\n\n'
                      'Aqui você controla o caixa e as despesas da empresa:\n\n'
                      '• Lançamentos: Clique no botão + abaixo para lançar despesas, receitas ou usar a IA para ler boletos e contas através de fotos ou PDFs.\n'
                      '• Importação Inteligente (CSV): Utilize o ícone superior (tabela) para importar, conciliar obras/contas e cadastrar transações em lote com checagem de duplicidade.\n'
                      '• Livro Caixa: Acompanhe todas as movimentações aprovadas e pendentes (ex: Faturas de folha de pagamento).\n'
                      '• Vales: Controle adiantamentos feitos a funcionários.',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Entendi'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calculate),
            tooltip: 'Calculadora',
            onPressed: () => CalculadoraFinanceiraModal.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.fact_check, color: Colors.orange),
            tooltip: 'Aprovações Pendentes',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AprovacoesPendentesScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.import_export),
            tooltip: 'Conciliação OFX',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OfxImportScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.table_view),
            tooltip: 'Importar CSV',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportacaoCsvScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Previsão de Caixa (IA)',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrevisaoIaScreen())),
          ),
          if (ref.watch(appUserProvider)?['role'] == 'MASTER')
            IconButton(
              icon: const Icon(Icons.security, color: Colors.amber),
              tooltip: 'Auditoria Inteligente (MASTER)',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditoriaFinanceiraScreen())),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuração Contábil',
            onPressed: () => context.push('/configuracao-contabil'),
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.account_balance), text: 'Fluxo de Caixa'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Vales e Adiantamentos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCaixaTab(),
          _buildValesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(heroTag: 'addBtn',
        onPressed: () {
          if (_tabController.index == 0) {
            showModalBottomSheet(
              context: context,
              builder: (ctx) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.arrow_downward, color: Colors.red),
                    title: const Text('Nova Despesa'),
                    onTap: () {
                      Navigator.pop(ctx);
                      TransacaoModal.show(context, isReceita: false);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.arrow_upward, color: Colors.green),
                    title: const Text('Nova Receita'),
                    onTap: () {
                      Navigator.pop(ctx);
                      TransacaoModal.show(context, isReceita: true);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.document_scanner, color: Colors.blue),
                    title: const Text('Escanear Boleto / Conta (IA)'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _mostrarOpcoesScan(context);
                    },
                  ),
                ],
              ),
            );
          } else {
            ValeModal.show(context);
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Lançamento' : 'Novo Vale'),
      ),
    );
  }

  void _mostrarOpcoesScan(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Tirar Foto (Câmera)'),
            onTap: () {
              Navigator.pop(ctx);
              _processarScan(context, ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Escolher da Galeria'),
            onTap: () {
              Navigator.pop(ctx);
              _processarScan(context, ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('Escanear PDF/Imagem (IA)'),
            onTap: () {
              Navigator.pop(ctx);
              _processarPdf(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt),
            title: const Text('Importar NF-e (XML)'),
            onTap: () {
              Navigator.pop(ctx);
              _processarXml(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _processarScan(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      if (image == null) return;
      
      final bytes = await image.readAsBytes();
      
      // Comprimir a imagem
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1024,
        minHeight: 1024,
        quality: 60,
        format: CompressFormat.jpeg,
      );
      
      final base64String = base64Encode(compressedBytes);
      
      _enviarParaBackend(context, base64String, 'image/jpeg');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao capturar imagem: $e')));
    }
  }

  Future<void> _processarPdf(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        final path = result.files.single.path;
        if (path != null) {
          final bytes = await File(path).readAsBytes();
          final base64String = base64Encode(bytes);
          _enviarParaBackend(context, base64String, 'application/pdf');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao ler PDF: $e')));
    }
  }

  Future<void> _processarXml(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xml'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        if (file.bytes != null) {
          final xmlString = utf8.decode(file.bytes!);
          final document = XmlDocument.parse(xmlString);
          
          String valor = '0.0';
          String descricao = 'NF-e Importada';
          String dataVencimentoStr = '';
          
          try {
            final vNFElements = document.findAllElements('vNF');
            if (vNFElements.isNotEmpty) {
              valor = vNFElements.first.innerText;
            }
            
            final emitElements = document.findAllElements('emit');
            if (emitElements.isNotEmpty) {
               final xNomeElements = emitElements.first.findElements('xNome');
               if (xNomeElements.isNotEmpty) {
                 descricao = xNomeElements.first.innerText;
               }
            }
            
            final dhEmiElements = document.findAllElements('dhEmi');
            if (dhEmiElements.isNotEmpty) {
              dataVencimentoStr = dhEmiElements.first.innerText;
            }
          } catch (e) {
            debugPrint('Erro ao extrair campos do XML: $e');
          }

          if (context.mounted) {
            final transacaoExtraida = {
              'descricao': descricao,
              'valor': double.tryParse(valor) ?? 0.0,
              'dataVencimento': dataVencimentoStr,
              'tipo': 'DESPESA',
              'status': 'PENDENTE',
            };
            
            TransacaoModal.show(context, isReceita: false, transacao: transacaoExtraida);
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao processar XML: $e')));
      }
    }
  }

  Future<void> _enviarParaBackend(BuildContext context, String base64String, String mimeType) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Chamar a IA para escanear
      final response = await ref.read(financeiroControllerProvider.notifier).scanConta(base64String, mimeType);
      
      // 2. Fazer upload do arquivo no Storage
      final fileUrl = await ref.read(financeiroControllerProvider.notifier).uploadComprovante(base64String, mimeType, 'anexo_scan');

      if (context.mounted) {
        Navigator.pop(context); // close loading
        
        // Formatar para transacao
        final transacaoExtraida = {
          'descricao': response['descricao'],
          'valor': response['valor'],
          'dataVencimento': response['dataVencimento'],
          'codigoBarras': response['codigoBarras'],
          'comprovanteUrl': fileUrl,
          'tipo': 'DESPESA',
          'status': 'PENDENTE',
        };

        TransacaoModal.show(context, isReceita: false, transacao: transacaoExtraida);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro na IA: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildCaixaTab() {
    final transacoesAsync = ref.watch(transacoesProvider);
    
    return transacoesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erro: $err')),
      data: (transacoes) {
        if (transacoes.isEmpty) {
          return const Center(child: Text('Nenhuma transação encontrada.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: transacoes.length,
          itemBuilder: (context, index) {
            final t = transacoes[index];
            final isReceita = t['tipo'] == 'RECEITA';
            return Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                leading: CircleAvatar(
                  backgroundColor: isReceita ? Colors.green.shade50 : Colors.red.shade50,
                  child: Icon(
                    isReceita ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isReceita ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(
                  t['descricao'] ?? '', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    // Plano de Contas / Categoria
                    Row(
                      children: [
                        const Icon(Icons.account_tree_outlined, size: 13, color: Colors.blueGrey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            t['categoriaFk'] != null
                                ? '${t['categoriaFk']['codigo'] != null ? '${t['categoriaFk']['codigo']} - ' : ''}${t['categoriaFk']['descricao'] ?? t['categoriaFk']['nome']}'
                                : 'Sem Plano de Contas',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Badges: Conta Bancária / Caixa + Colaborador / Fornecedor + OFX
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (t['contaBancaria'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue.shade200, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.account_balance, size: 11, color: Colors.blue.shade800),
                                const SizedBox(width: 4),
                                Text(
                                  t['contaBancaria']['nome'],
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                                ),
                              ],
                            ),
                          ),
                        if (t['funcionario'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.purple.shade200, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person, size: 11, color: Colors.purple.shade800),
                                const SizedBox(width: 4),
                                Text(
                                  t['funcionario']['nome'] ?? '',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple.shade900),
                                ),
                              ],
                            ),
                          )
                        else if (t['clienteFornecedor'] != null && (t['clienteFornecedor'] as String).isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange.shade200, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.storefront, size: 11, color: Colors.orange.shade800),
                                const SizedBox(width: 4),
                                Text(
                                  t['clienteFornecedor'],
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                                ),
                              ],
                            ),
                          ),
                        if (t['obra'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.teal.shade200, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.apartment, size: 11, color: Colors.teal.shade800),
                                const SizedBox(width: 4),
                                Text(
                                  t['obra']['nome'] ?? '',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                                ),
                              ],
                            ),
                          ),
                        if (t['isConciliada'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                            child: const Text('OFX', style: TextStyle(fontSize: 8, color: Colors.green, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (t['comprovanteUrl'] != null)
                      const Icon(Icons.attachment, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      'R\$ ${(double.tryParse(t['valor']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isReceita ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Badge interativo PAGO / PENDENTE / A CONFIRMAR
                    PopupMenuButton<String>(
                      tooltip: 'Alterar Status',
                      onSelected: (novoStatus) async {
                        try {
                          await ref.read(financeiroControllerProvider.notifier).updateTransacao(t['id'], {
                            'status': novoStatus,
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Transação marcada como ${novoStatus == 'A_CONFIRMAR' ? 'A CONFIRMAR' : novoStatus}!'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro ao alterar status: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'PAGO',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 16),
                              SizedBox(width: 8),
                              Text('PAGO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'PENDENTE',
                          child: Row(
                            children: [
                              Icon(Icons.schedule, color: Colors.amber, size: 16),
                              SizedBox(width: 8),
                              Text('PENDENTE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'A_CONFIRMAR',
                          child: Row(
                            children: [
                              Icon(Icons.help_outline, color: Colors.deepPurple, size: 16),
                              SizedBox(width: 8),
                              Text('A CONFIRMAR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (t['status'] == 'PAGO')
                              ? Colors.green.shade50
                              : (t['status'] == 'A_CONFIRMAR' || t['status'] == 'A CONFIRMAR')
                                  ? Colors.deepPurple.shade50
                                  : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: (t['status'] == 'PAGO')
                                ? Colors.green.shade400
                                : (t['status'] == 'A_CONFIRMAR' || t['status'] == 'A CONFIRMAR')
                                    ? Colors.deepPurple.shade400
                                    : Colors.amber.shade600,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (t['status'] == 'PAGO')
                                  ? Icons.check_circle
                                  : (t['status'] == 'A_CONFIRMAR' || t['status'] == 'A CONFIRMAR')
                                      ? Icons.help_outline
                                      : Icons.schedule,
                              size: 13,
                              color: (t['status'] == 'PAGO')
                                  ? Colors.green.shade700
                                  : (t['status'] == 'A_CONFIRMAR' || t['status'] == 'A CONFIRMAR')
                                      ? Colors.deepPurple.shade700
                                      : Colors.amber.shade900,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              (t['status'] == 'A_CONFIRMAR' || t['status'] == 'A CONFIRMAR')
                                  ? 'A CONFIRMAR'
                                  : (t['status'] ?? 'PENDENTE'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: (t['status'] == 'PAGO')
                                    ? Colors.green.shade800
                                    : (t['status'] == 'A_CONFIRMAR' || t['status'] == 'A CONFIRMAR')
                                        ? Colors.deepPurple.shade800
                                        : Colors.amber.shade900,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_drop_down,
                              size: 14,
                              color: (t['status'] == 'PAGO')
                                  ? Colors.green.shade800
                                  : (t['status'] == 'A_CONFIRMAR' || t['status'] == 'A CONFIRMAR')
                                      ? Colors.deepPurple.shade800
                                      : Colors.amber.shade900,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        TransacaoModal.show(context, isReceita: isReceita, transacao: t);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        try {
                          await ref.read(financeiroControllerProvider.notifier).deleteTransacao(t['id']);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Transação excluída com sucesso!')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildValesTab() {
    final valesAsync = ref.watch(valesProvider);
    
    return valesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erro: $err')),
      data: (vales) {
        if (vales.isEmpty) {
          return const Center(child: Text('Nenhum vale emitido.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: vales.length,
          itemBuilder: (context, index) {
            final v = vales[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: const Icon(Icons.person, color: Colors.blue),
                ),
                title: Text(
                  v['funcionario']?['nome'] ?? 'Funcionário Desconhecido', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(v['tipo'] ?? 'Salarial', style: const TextStyle(fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'R\$ ${(double.tryParse(v['valor']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            v['status'] ?? 'ABERTO',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _mostrarEdicaoVale(context, v),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        try {
                          await ref.read(financeiroControllerProvider.notifier).deleteVale(v['id']);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vale excluído com sucesso!')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarEdicaoVale(BuildContext context, dynamic vale) {
    String? funcionarioSelecionado = vale['funcionarioId'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Vale / Adiantamento'),
          content: Consumer(
            builder: (context, ref, child) {
              final funcsAsync = ref.watch(funcionariosProvider);
              return funcsAsync.when(
                loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
                error: (e, st) => Text('Erro ao carregar funcionários: $e'),
                data: (funcs) {
                  return DropdownButtonFormField<String>(
                    value: funcs.any((f) => f['id'] == funcionarioSelecionado) ? funcionarioSelecionado : null,
                    decoration: const InputDecoration(
                      labelText: 'Funcionário',
                      border: OutlineInputBorder(),
                    ),
                    items: funcs.map((f) => DropdownMenuItem<String>(
                      value: f['id'],
                      child: Text(f['nome']),
                    )).toList(),
                    onChanged: (val) {
                      funcionarioSelecionado = val;
                    },
                  );
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final data = {
                    'funcionarioId': funcionarioSelecionado,
                  };
                  await ref.read(financeiroControllerProvider.notifier).updateVale(vale['id'], data);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vale atualizado com sucesso!')),
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
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}

