import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/api_client_provider.dart';

class ItemBuscaGlobal {
  final String id;
  final String tipo; // OBRA, CLIENTE, FUNCIONARIO, CONTATO, ORDEM_COMPRA, ACAO
  final String titulo;
  final String subtitulo;
  final String icone;
  final String rota;
  final Map<String, dynamic>? dados;

  ItemBuscaGlobal({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    required this.rota,
    this.dados,
  });

  factory ItemBuscaGlobal.fromJson(Map<String, dynamic> json) {
    return ItemBuscaGlobal(
      id: json['id'] ?? '',
      tipo: json['tipo'] ?? 'GERAL',
      titulo: json['titulo'] ?? '',
      subtitulo: json['subtitulo'] ?? '',
      icone: json['icone'] ?? 'search',
      rota: json['rota'] ?? '/',
      dados: json['dados'] is Map<String, dynamic> ? json['dados'] : null,
    );
  }
}

class CommandCenterDialog extends ConsumerStatefulWidget {
  final Function(int) onNavigateTab;

  const CommandCenterDialog({super.key, required this.onNavigateTab});

  static void show(BuildContext context, {required Function(int) onNavigateTab}) {
    showDialog(
      context: context,
      builder: (_) => CommandCenterDialog(onNavigateTab: onNavigateTab),
    );
  }

  @override
  ConsumerState<CommandCenterDialog> createState() => _CommandCenterDialogState();
}

class _CommandCenterDialogState extends ConsumerState<CommandCenterDialog> {
  final _searchController = TextEditingController();
  List<ItemBuscaGlobal> _resultados = [];
  bool _loading = false;
  Timer? _debounceTimer;

  // Ações de sistema para acesso rápido
  final List<ItemBuscaGlobal> _atalhosRapidos = [
    ItemBuscaGlobal(
      id: 'acao_obras',
      tipo: 'ACAO',
      titulo: 'Ir para Canteiro de Obras',
      subtitulo: 'Painel de RDO, Medições, FVS e Vistorias 360',
      icone: 'construction',
      rota: 'TAB_1',
    ),
    ItemBuscaGlobal(
      id: 'acao_fin',
      tipo: 'ACAO',
      titulo: 'Ir para Financeiro & DRE',
      subtitulo: 'Livro Caixa, Fluxo, Conciliação OFX/PDF e Auditoria',
      icone: 'account_balance_wallet',
      rota: 'TAB_2',
    ),
    ItemBuscaGlobal(
      id: 'acao_agenda',
      tipo: 'ACAO',
      titulo: 'Abrir Agenda & Compromissos',
      subtitulo: 'Reuniões, Convites e Agenda Telefônica WhatsApp',
      icone: 'calendar_month',
      rota: 'TAB_4',
    ),
    ItemBuscaGlobal(
      id: 'acao_suprimentos',
      tipo: 'ACAO',
      titulo: 'Suprimentos & Ordens de Compra',
      subtitulo: 'Tabela de cotações, Alertas de Sobrepreço e Estoque',
      icone: 'inventory_2',
      rota: 'TAB_5',
    ),
    ItemBuscaGlobal(
      id: 'acao_crm',
      tipo: 'ACAO',
      titulo: 'Vendas & CRM de Clientes',
      subtitulo: 'Funil comercial, Propostas e Clientes',
      icone: 'handshake',
      rota: 'TAB_6',
    ),
    ItemBuscaGlobal(
      id: 'acao_chat',
      tipo: 'ACAO',
      titulo: 'Abrir Mensageria Interna (Chat)',
      subtitulo: 'Conversas diretas e canais de obras',
      icone: 'forum',
      rota: 'ROTA_CHAT',
    ),
  ];

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _resultados = [];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    _debounceTimer = Timer(const Duration(milliseconds: 250), () async {
      try {
        final api = ref.read(apiClientProvider);
        final response = await api.get('/global-search?q=${Uri.encodeComponent(query.trim())}');
        if (response['resultados'] is List && mounted) {
          setState(() {
            _resultados = (response['resultados'] as List)
                .map((item) => ItemBuscaGlobal.fromJson(item))
                .toList();
            _loading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  void _executarItem(ItemBuscaGlobal item) {
    Navigator.of(context).pop();
    if (item.rota == 'TAB_1') {
      widget.onNavigateTab(1);
    } else if (item.rota == 'TAB_2') {
      widget.onNavigateTab(2);
    } else if (item.rota == 'TAB_4') {
      widget.onNavigateTab(4);
    } else if (item.rota == 'TAB_5') {
      widget.onNavigateTab(5);
    } else if (item.rota == 'TAB_6') {
      widget.onNavigateTab(6);
    } else if (item.rota == 'ROTA_CHAT') {
      Navigator.of(context).pushNamed('/chat');
    } else if (item.tipo == 'OBRA') {
      widget.onNavigateTab(1);
    } else if (item.tipo == 'CONTATO') {
      widget.onNavigateTab(4);
    } else if (item.tipo == 'ORDEM_COMPRA') {
      widget.onNavigateTab(5);
    } else if (item.tipo == 'CLIENTE') {
      widget.onNavigateTab(6);
    } else if (item.tipo == 'FUNCIONARIO') {
      widget.onNavigateTab(3);
    }
  }

  IconData _obterIcone(String nome) {
    switch (nome) {
      case 'apartment':
        return Icons.apartment;
      case 'construction':
        return Icons.construction;
      case 'handshake':
        return Icons.handshake;
      case 'people':
        return Icons.people;
      case 'contact_phone':
        return Icons.contact_phone;
      case 'inventory_2':
        return Icons.inventory_2;
      case 'calendar_month':
        return Icons.calendar_month;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'forum':
        return Icons.forum_outlined;
      default:
        return Icons.chevron_right;
    }
  }

  @override
  Widget build(BuildContext context) {
    final itensExibidos = _searchController.text.trim().length >= 2 ? _resultados : _atalhosRapidos;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        width: 650,
        constraints: const BoxConstraints(maxHeight: 520),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // BARRA DE INPUT ESTILO RAYCAST / LINEAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 22, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: _onSearchChanged,
                      decoration: const InputDecoration(
                        hintText: 'Digite o que procura... (ex: Obra, Cliente, Ordem de Compra, Fornecedor)',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('ESC para fechar', style: TextStyle(fontSize: 10, color: Colors.black54)),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),

            // LISTA DE ITENS
            Expanded(
              child: itensExibidos.isEmpty && !_loading
                  ? Center(
                      child: Text(
                        'Nenhum resultado encontrado para "${_searchController.text}"',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: itensExibidos.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, indent: 60),
                      itemBuilder: (context, index) {
                        final item = itensExibidos[index];
                        final isAcao = item.tipo == 'ACAO';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isAcao ? Colors.blue.shade50 : Colors.indigo.shade50,
                            child: Icon(_obterIcone(item.icone), color: isAcao ? Colors.blue.shade800 : Colors.indigo.shade800, size: 20),
                          ),
                          title: Text(item.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(item.subtitulo, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          onTap: () => _executarItem(item),
                        );
                      },
                    ),
            ),

            // RODAPÉ DO COMMAND CENTER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.keyboard_outlined, size: 14, color: Colors.grey),
                  SizedBox(width: 6),
                  Text('Dica: Use as setas e Enter para navegar rapidamente.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Spacer(),
                  Text('Command Center v2.0', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
