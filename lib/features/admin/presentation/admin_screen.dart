import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'tenant_modal.dart';
import '../../../shared/providers/api_client_provider.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  List<dynamic> _usuarios = [];
  List<dynamic> _empresas = [];
  List<dynamic> _logs = [];
  bool _isLoading = false;
  bool _isLoadingLogs = false;
  String _filtroModulo = 'TODOS';

  final List<String> _modulos = [
    'TODOS',
    'FINANCEIRO',
    'SUPRIMENTOS',
    'RH',
    'OBRAS',
    'SISTEMA'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadLogs();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final usersRes = await api.get('/admin/usuarios');
      final tenantsRes = await api.get('/tenants');
      
      setState(() {
        _usuarios = usersRes['data'] ?? [];
        _empresas = tenantsRes['data'] ?? [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoadingLogs = true);
    try {
      final api = ref.read(apiClientProvider);
      String url = '/admin/auditoria?limit=50';
      if (_filtroModulo != 'TODOS') {
        url += '&modulo=$_filtroModulo';
      }
      final res = await api.get(url);
      setState(() {
        _logs = res['data'] ?? [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar logs: $e')));
      }
    } finally {
      setState(() => _isLoadingLogs = false);
    }
  }

  Future<void> _aprovarUsuario(String userId, String tenantId) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.put('/admin/usuarios/$userId', {
        'status': 'ATIVO',
        'tenantId': tenantId,
        'role': 'USER'
      });
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _editarUsuario(dynamic u) async {
    final phoneController = TextEditingController(text: u['telefone']?.toString() ?? '');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar ${u['nome']}'),
        content: TextField(
          controller: phoneController,
          decoration: const InputDecoration(labelText: 'WhatsApp (Ex: 5511999999999)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              try {
                final api = ref.read(apiClientProvider);
                await api.put('/admin/usuarios/${u['id']}', {
                  'telefone': phoneController.text.trim(),
                });
                if (mounted && ctx.mounted) Navigator.pop(ctx);
                _loadData();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Aprovar Usuários', icon: Icon(Icons.person_add)),
              Tab(text: 'Empresas', icon: Icon(Icons.business)),
              Tab(text: 'WhatsApp', icon: Icon(Icons.chat)),
              Tab(text: 'Auditoria', icon: Icon(Icons.security)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildUsuariosTab(),
                _buildEmpresasTab(),
                _buildWhatsAppTab(),
                _buildAuditoriaTab(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildUsuariosTab() {
    if (_usuarios.isEmpty) return const Center(child: Text('Nenhum usuário encontrado.'));

    return ListView.builder(
      itemCount: _usuarios.length,
      itemBuilder: (context, index) {
        final u = _usuarios[index];
        final isPendente = u['status'] == 'PENDENTE';
        String selectedTenant = _empresas.isNotEmpty ? _empresas.first['id'] : '';
        
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(u['nome'] ?? 'Sem Nome'),
            subtitle: Text('${u['email'] ?? 'Sem Email'} - Tel/WhatsApp: ${u['telefone'] ?? 'Não cadastrado'}'),
            trailing: isPendente ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: selectedTenant.isNotEmpty ? selectedTenant : null,
                  items: _empresas.map((e) => DropdownMenuItem<String>(
                    value: e['id'],
                    child: Text(e['nome']),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      _aprovarUsuario(u['id'], val);
                    }
                  },
                  hint: const Text('Aprovar para...'),
                )
              ],
            ) : IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editarUsuario(u),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpresasTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_empresas.length} empresa(s) cadastrada(s)',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_business, size: 18),
                label: const Text('Nova Empresa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => TenantModal.show(context, onSuccess: _loadData),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _empresas.isEmpty
              ? const Center(child: Text('Nenhuma empresa cadastrada.'))
              : ListView.builder(
                  itemCount: _empresas.length,
                  itemBuilder: (context, index) {
                    final e = _empresas[index];
                    final counts = e['_count'] ?? {};
                    final numObras = counts['obras'] ?? 0;
                    final numUsuarios = counts['usuarios'] ?? 0;
                    final numCategorias = counts['categoriasFinanceiras'] ?? 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: _buildEmpresaLogo(e['logoUrl'], e['nome']),
                        title: Text(
                          e['nome'] ?? 'Sem Nome',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CNPJ/CPF: ${e['documento'] ?? 'N/A'}', style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              children: [
                                Chip(
                                  label: Text('$numObras obras', style: const TextStyle(fontSize: 10)),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                                Chip(
                                  label: Text('$numUsuarios usuários', style: const TextStyle(fontSize: 10)),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                                Chip(
                                  label: Text('$numCategorias categorias', style: const TextStyle(fontSize: 10)),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.category_outlined, color: Colors.indigo),
                              tooltip: 'Ver Categorias Financeiras',
                              onPressed: () => _exibirCategoriasEmpresa(e),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.black87),
                              tooltip: 'Editar Empresa e Logo',
                              onPressed: () => TenantModal.show(context, tenant: e, onSuccess: _loadData),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmpresaLogo(String? logoUrl, String? nome) {
    if (logoUrl != null && logoUrl.isNotEmpty) {
      if (logoUrl.startsWith('data:')) {
        try {
          final clean = logoUrl.split(',').last;
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(base64Decode(clean), width: 44, height: 44, fit: BoxFit.cover),
          );
        } catch (_) {}
      } else {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            logoUrl,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(nome),
          ),
        );
      }
    }
    return _buildFallbackAvatar(nome);
  }

  Widget _buildFallbackAvatar(String? nome) {
    final letra = (nome != null && nome.isNotEmpty) ? nome[0].toUpperCase() : 'E';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.indigo.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          letra,
          style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }

  Future<void> _exibirCategoriasEmpresa(dynamic e) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.category, color: Colors.indigo),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Categorias - ${e['nome']}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder(
            future: ref.read(apiClientProvider).get('/tenants/${e['id']}'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erro: ${snapshot.error}'));
              }
              final tenantData = (snapshot.data as Map<String, dynamic>?)?['data'];
              final List<dynamic> categorias = tenantData?['categoriasFinanceiras'] ?? [];

              if (categorias.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Nenhuma categoria financeira cadastrada para esta empresa.'),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                itemCount: categorias.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final cat = categorias[idx];
                  final isReceita = cat['tipo'] == 'RECEITA';
                  return ListTile(
                    dense: true,
                    leading: Chip(
                      label: Text(
                        cat['codigo'] ?? '',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    title: Text(cat['descricao'] ?? '', style: const TextStyle(fontSize: 13)),
                    trailing: Text(
                      cat['tipo'] ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isReceita ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppTab() {
    return FutureBuilder(
      future: ref.read(apiClientProvider).get('/whatsapp/connect'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }
        
        final data = snapshot.data as Map<String, dynamic>?;
        if (data == null) return const Center(child: Text('Nenhum dado retornado'));

        if (data['state'] == 'open') {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 80),
                const SizedBox(height: 16),
                const Text('WhatsApp Conectado!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Atualizar Status'),
                  onPressed: () => setState(() {}),
                )
              ],
            ),
          );
        }

        final qrData = data['qrData'];
        final base64String = qrData?['base64'];

        if (base64String == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Status atual: ${data['state']} (QR não disponível)'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar Novamente'),
                  onPressed: () => setState(() {}),
                )
              ],
            )
          );
        }

        final cleanBase64 = base64String.contains(',') 
            ? base64String.split(',')[1] 
            : base64String;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Escaneie o QR Code para conectar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Image.memory(
                base64Decode(cleanBase64),
                width: 300,
                height: 300,
                errorBuilder: (c,e,s) => const Text('Erro ao renderizar QR Code'),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Atualizar QR Code'),
                onPressed: () => setState(() {}),
              )
            ],
          ),
        );
      }
    );
  }

  Widget _buildAuditoriaTab() {
    return Column(
      children: [
        // Barra de Filtros por Módulo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.grey.shade50,
          child: Row(
            children: [
              const Text('Módulo: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _modulos.map((mod) {
                      final isSelected = _filtroModulo == mod;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(mod),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _filtroModulo = mod);
                              _loadLogs();
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Recarregar logs',
                onPressed: _loadLogs,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Lista de Logs
        Expanded(
          child: _isLoadingLogs
              ? const Center(child: CircularProgressIndicator())
              : _logs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text('Nenhum log encontrado para o filtro selecionado.',
                              style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadLogs,
                      child: ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          final usuario = log['usuario'] ?? {};
                          final acao = log['acao'] ?? 'AÇÃO';
                          final modulo = log['modulo'] ?? 'GERAL';
                          final rawDate = log['createdAt'];
                          String dataFormatada = '';
                          if (rawDate != null) {
                            try {
                              final dt = DateTime.parse(rawDate).toLocal();
                              dataFormatada = DateFormat('dd/MM/yyyy HH:mm:ss').format(dt);
                            } catch (_) {
                              dataFormatada = rawDate.toString();
                            }
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            elevation: 1.5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: _buildModuloBadge(modulo),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      acao.replaceAll('_', ' '),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    dataFormatada,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Por: ${usuario['nome'] ?? 'Sistema'} (${usuario['email'] ?? 'N/A'})',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.info_outline, color: Colors.indigo),
                                tooltip: 'Ver Detalhes',
                                onPressed: () => _exibirDetalhesLog(log),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildModuloBadge(String modulo) {
    Color bg;
    IconData icon;

    switch (modulo.toUpperCase()) {
      case 'FINANCEIRO':
        bg = Colors.green.shade700;
        icon = Icons.attach_money;
        break;
      case 'SUPRIMENTOS':
        bg = Colors.orange.shade800;
        icon = Icons.inventory_2;
        break;
      case 'RH':
        bg = Colors.purple.shade700;
        icon = Icons.people;
        break;
      case 'OBRAS':
        bg = Colors.blue.shade700;
        icon = Icons.construction;
        break;
      default:
        bg = Colors.blueGrey;
        icon = Icons.settings;
    }

    return CircleAvatar(
      backgroundColor: bg.withValues(alpha: 0.15),
      child: Icon(icon, color: bg, size: 20),
    );
  }

  void _exibirDetalhesLog(dynamic log) {
    dynamic detalhesParsed;
    if (log['detalhes'] != null) {
      if (log['detalhes'] is String) {
        try {
          detalhesParsed = jsonDecode(log['detalhes']);
        } catch (_) {
          detalhesParsed = log['detalhes'];
        }
      } else {
        detalhesParsed = log['detalhes'];
      }
    }

    final encoder = const JsonEncoder.withIndent('  ');
    final formattedJson = detalhesParsed != null
        ? (detalhesParsed is Map || detalhesParsed is List
            ? encoder.convert(detalhesParsed)
            : detalhesParsed.toString())
        : 'Nenhum detalhe extra registrado.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.security, color: Colors.indigo),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Detalhes: ${log['acao'] ?? ''}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow('ID do Evento', log['id'] ?? '-'),
                _buildInfoRow('Módulo', log['modulo'] ?? '-'),
                _buildInfoRow('Usuário', '${log['usuario']?['nome'] ?? 'Sistema'} (${log['usuario']?['email'] ?? '-'})'),
                _buildInfoRow('Data/Hora', log['createdAt'] ?? '-'),
                if (log['tenant']?['nome'] != null)
                  _buildInfoRow('Empresa (Tenant)', log['tenant']['nome']),
                const SizedBox(height: 12),
                const Text(
                  'Carga de Dados (Payload / Alterações):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SelectableText(
                    formattedJson,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Colors.lightGreenAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 12),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}


