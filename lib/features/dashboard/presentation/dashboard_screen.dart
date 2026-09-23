import 'package:flutter/material.dart';
import '../../agenda/presentation/agenda_screen.dart';
import '../../rh/presentation/rh_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../../shared/providers/api_client_provider.dart';
import '../../obras/presentation/obras_screen.dart';
import '../../financeiro/presentation/financeiro_screen.dart';
import '../../admin/presentation/admin_screen.dart';
import '../../relatorios/presentation/relatorios_screen.dart';
import '../../relatorios/presentation/livro_caixa_screen.dart';
import '../../suprimentos/presentation/screens/suprimentos_dashboard_screen.dart';
import '../../crm/presentation/screens/crm_dashboard_screen.dart';
import '../../rh/presentation/rh_dashboard_screen.dart';
import '../../frota/presentation/screens/frota_screen.dart';
import '../../auth/providers/tenant_provider.dart';
import '../../ai/presentation/gemini_chat_widget.dart';
import '../../ajuda/presentation/manual_screen.dart';
import 'package:intl/intl.dart';
import 'widgets/dre_dashboard_view.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;
  List<dynamic> _tenants = [];
  bool _isLoadingTenants = false;

  @override
  void initState() {
    super.initState();
    _loadTenantsIfMaster();
  }

  Future<void> _loadTenantsIfMaster() async {
    // Carregar tenants se for master para o seletor
    final user = ref.read(appUserProvider);
    if (user != null && user['role'] == 'MASTER') {
      setState(() => _isLoadingTenants = true);
      try {
        final api = ref.read(apiClientProvider);
        final res = await api.get('/tenants');
        setState(() {
          _tenants = res['data'] ?? [];
        });
      } catch (e) {
        // ignora
      } finally {
        if (mounted) setState(() => _isLoadingTenants = false);
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() {
    ref.read(authControllerProvider.notifier).signOut();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(appUserProvider);
    final isMaster = userData?['role'] == 'MASTER';
    final currentTenantId = ref.watch(tenantOverrideProvider);
    
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ERP Controle & Gestão'),
        elevation: 2,
        actions: [
          if (isMaster)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _isLoadingTenants 
                ? const Center(child: CircularProgressIndicator())
                : DropdownButton<String?>(
                    value: _tenants.any((t) => t['id'] == currentTenantId) ? currentTenantId : null,
                    hint: const Text('Selecionar Empresa', style: TextStyle(color: Colors.white)),
                    dropdownColor: Theme.of(context).primaryColor,
                    style: const TextStyle(color: Colors.white),
                    iconEnabledColor: Colors.white,
                    underline: const SizedBox(),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Painel Global (Master)')),
                      ..._tenants.map((t) => DropdownMenuItem<String>(
                        value: t['id'],
                        child: Text(t['nome']),
                      )).toList(),
                    ],
                    onChanged: (val) {
                      ref.read(tenantOverrideProvider.notifier).setTenant(val);
                      // Recarrega o dashboard
                      ref.invalidate(dashboardSummaryProvider);
                    },
                  ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Sair',
          ),
        ],
      ),
      drawer: isDesktop ? null : _buildDrawer(userData?['email'], isMaster, userData?['role'] ?? 'USER'),
      body: Row(
        children: [
          if (isDesktop) 
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: _buildNavigationRail(isMaster, userData?['role'] ?? 'USER'),
                    ),
                  ),
                );
              },
            ),
          if (isDesktop) const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _buildContent(_selectedIndex, isMaster),
          ),
        ],
      ),
      floatingActionButton: const GeminiChatWidget(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
    );
  }

  Widget _buildDrawer(String? email, bool isMaster, String role) {
    bool hasRole(List<String> roles) => isMaster || roles.contains(role);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('Usuário'),
            accountEmail: Text(email ?? 'Sem E-mail'),
            currentAccountPicture: DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue.shade50),
              child: Image.asset(
                'assets/images/logo.png',
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.account_balance,
                  size: 48,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Livro Caixa'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LivroCaixaScreen()),
              );
            },
          ),
          ..._buildMenuItens(isMaster, role),
        ],
      ),
    );
  }

  Widget _buildNavigationRail(bool isMaster, String role) {
    bool hasRole(List<String> roles) => isMaster || roles.contains(role);
    final allowedDestinations = <MapEntry<int, NavigationRailDestination>>[
      if (hasRole(['ENGENHARIA', 'FINANCEIRO', 'ALMOXARIFE', 'RH']))
        const MapEntry(0, NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Início'),
        )),
      if (hasRole(['ENGENHARIA']))
        const MapEntry(1, NavigationRailDestination(
          icon: Icon(Icons.construction_outlined),
          selectedIcon: Icon(Icons.construction),
          label: Text('Obras'),
        )),
      if (hasRole(['FINANCEIRO']))
        const MapEntry(2, NavigationRailDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: Text('Financeiro'),
        )),
      if (hasRole(['RH']))
        const MapEntry(3, NavigationRailDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: Text('RH'),
        )),
      if (hasRole(['VENDAS']))
        const MapEntry(4, NavigationRailDestination(
          icon: Icon(Icons.contacts_outlined),
          selectedIcon: Icon(Icons.contacts),
          label: Text('Agenda'),
        )),
      if (hasRole(['ALMOXARIFE', 'ENGENHARIA', 'FINANCEIRO']))
        const MapEntry(5, NavigationRailDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: Text('Suprimentos'),
        )),
      if (hasRole(['VENDAS']))
        const MapEntry(6, NavigationRailDestination(
          icon: Icon(Icons.handshake_outlined),
          selectedIcon: Icon(Icons.handshake),
          label: Text('Vendas / CRM'),
        )),
      if (hasRole(['ENGENHARIA', 'ALMOXARIFE']))
        const MapEntry(7, NavigationRailDestination(
          icon: Icon(Icons.directions_car_outlined),
          selectedIcon: Icon(Icons.directions_car),
          label: Text('Frota'),
        )),
      if (isMaster)
        const MapEntry(8, NavigationRailDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: Text('Admin'),
        )),
    ];

    int relativeIndex = allowedDestinations.indexWhere((entry) => entry.key == _selectedIndex);
    if (relativeIndex == -1 && allowedDestinations.isNotEmpty) {
      relativeIndex = 0; // Fallback
    }

    return NavigationRail(
      selectedIndex: allowedDestinations.isEmpty ? null : relativeIndex,
      onDestinationSelected: (idx) => _onItemTapped(allowedDestinations[idx].key),
      labelType: NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, top: 16.0),
        child: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: const Icon(Icons.business),
        ),
      ),
      destinations: allowedDestinations.map((e) => e.value).toList(),
      trailing: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RelatoriosScreen()),
                );
              },
              tooltip: 'Relatórios',
            ),
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManualScreen()),
                );
              },
              tooltip: 'Ajuda & Manual',
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMenuItens(bool isMaster, String role) {
    bool hasRole(List<String> roles) => isMaster || roles.contains(role);
    return [
      if (hasRole(['ENGENHARIA', 'FINANCEIRO', 'ALMOXARIFE', 'RH']))
        ListTile(
          leading: const Icon(Icons.dashboard),
          title: const Text('Início'),
          selected: _selectedIndex == 0,
          onTap: () {
            _onItemTapped(0);
            Navigator.pop(context); // Fechar drawer
          },
        ),
      if (hasRole(['ENGENHARIA']))
        ListTile(
          leading: const Icon(Icons.construction),
          title: const Text('Obras'),
          selected: _selectedIndex == 1,
          onTap: () {
            _onItemTapped(1);
            Navigator.pop(context);
          },
        ),
      if (hasRole(['FINANCEIRO']))
        ListTile(
          leading: const Icon(Icons.account_balance_wallet),
          title: const Text('Financeiro'),
          selected: _selectedIndex == 2,
          onTap: () {
            _onItemTapped(2);
            Navigator.pop(context);
          },
        ),
      const Divider(),
      if (hasRole(['RH']))
        ListTile(
          leading: const Icon(Icons.people),
          title: const Text('RH / Equipe'),
          selected: _selectedIndex == 3,
          onTap: () {
            _onItemTapped(3);
            Navigator.pop(context);
          },
        ),
      if (hasRole(['FINANCEIRO', 'ENGENHARIA']))
        ListTile(
          leading: const Icon(Icons.picture_as_pdf),
          title: const Text('Relatórios'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RelatoriosScreen()),
            );
          },
        ),
      if (hasRole(['VENDAS']))
        ListTile(
          leading: const Icon(Icons.contacts),
          title: const Text('Agenda'),
          selected: _selectedIndex == 4,
          onTap: () {
            _onItemTapped(4);
            Navigator.pop(context);
          },
        ),
      if (hasRole(['ALMOXARIFE', 'ENGENHARIA', 'FINANCEIRO']))
        ListTile(
          leading: const Icon(Icons.inventory_2),
          title: const Text('Suprimentos'),
          selected: _selectedIndex == 5,
          onTap: () {
            _onItemTapped(5);
            Navigator.pop(context);
          },
        ),
      if (hasRole(['VENDAS']))
        ListTile(
          leading: const Icon(Icons.handshake),
          title: const Text('Vendas / CRM'),
          selected: _selectedIndex == 6,
          onTap: () {
            _onItemTapped(6);
            Navigator.pop(context);
          },
        ),
      if (hasRole(['ENGENHARIA', 'ALMOXARIFE']))
        ListTile(
          leading: const Icon(Icons.directions_car),
          title: const Text('Frota e Máquinas'),
          selected: _selectedIndex == 7,
          onTap: () {
            _onItemTapped(7);
            Navigator.pop(context);
          },
        ),
      ListTile(
        leading: const Icon(Icons.help_outline),
        title: const Text('Ajuda & Manual'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManualScreen()),
          );
        },
      ),
      const Divider(),
      if (isMaster)
        ListTile(
          leading: const Icon(Icons.admin_panel_settings),
          title: const Text('Painel Admin'),
          selected: _selectedIndex == 7,
          onTap: () {
            _onItemTapped(7);
            Navigator.pop(context);
          },
        ),
    ];
  }


  Widget _buildContent(dynamic route, bool isMaster) {
    switch (route) {
      case '/livro-caixa':
        return const LivroCaixaScreen();
      case '/relatorios':
        return _buildSummaryTab();
      case 0:
        return _buildSummaryTab();
      case 1:
        return const ObrasScreen();
      case 2:
        return const FinanceiroScreen();
      case 3:
        return const RhDashboardScreen();
      case 4:
        return const AgendaScreen();
      case 5:
        return const SuprimentosDashboardScreen();
      case 6:
        return const CrmDashboardScreen();
      case 7:
        return const FrotaScreen();
      case 8:
        if (isMaster) return const AdminScreen();
        return const Center(child: Text('Página não encontrada'));
      default:
        return const Center(child: Text('Página não encontrada'));
    }
  }

  Widget _buildSummaryTab() {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    
    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text('Erro ao carregar dados: $err', style: const TextStyle(color: Colors.red)),
      ),
      data: (data) {
        final isMaster = data['message'] != null;
        final isPendente = data['user']?['status'] == 'PENDENTE';
        final stats = data['stats'];
        
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMaster ? data['message'] : 'Visão Geral - ${data['empresa']}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF007A8D)),
              ),
              if (isPendente) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.orange.shade100,
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sua conta está aguardando aprovação pelo Administrador.',
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Expanded(
                child: isMaster 
                  ? GridView.count(
                      crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: _buildMasterCards(stats),
                    )
                  : _buildTenantDashboard(stats),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildMasterCards(Map<String, dynamic> stats) {
    return [
      _buildMetricCard('Empresas Ativas', stats['totalEmpresasAtivas']?.toString() ?? '0', Icons.business, Colors.blue),
      _buildMetricCard('Usuários Globais', stats['totalUsuariosGlobais']?.toString() ?? '0', Icons.people, Colors.green),
    ];
  }

  double _parseValue(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  Widget _buildTenantDashboard(Map<String, dynamic> stats) {
    final formatCurrency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Key Metrics
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 800;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: isDesktop ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                    child: _buildMetricCard('Saldo em Caixa', formatCurrency.format(_parseValue(stats['saldoEmCaixa'])), Icons.account_balance_wallet, Colors.teal),
                  ),
                  SizedBox(
                    width: isDesktop ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                    child: _buildMetricCard('Fluxo Realizado (Rec)', formatCurrency.format(_parseValue(stats['fluxo']?['receitasPagas'])), Icons.trending_up, Colors.green),
                  ),
                  SizedBox(
                    width: isDesktop ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                    child: _buildMetricCard('Obras Ativas', stats['obrasAtivas']?.toString() ?? '0', Icons.construction, Colors.orange),
                  ),
                  SizedBox(
                    width: isDesktop ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                    child: _buildMetricCard('Colaboradores', stats['colaboradoresAtivos']?.toString() ?? '0', Icons.people, Colors.blue),
                  ),
                ],
              );
            }
          ),
          const SizedBox(height: 32),
          
          // DRE Dashboard
          const DreDashboardView(),

          const SizedBox(height: 32),
          
          // Row 2: Vencimentos and Obras
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contas a Pagar
              Expanded(
                flex: 1,
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Contas a Pagar por Vencimento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Divider(),
                        _buildVencimentoRow('Hoje', stats['contasPagar']?['hoje'], Colors.red),
                        _buildVencimentoRow('Amanhã', stats['contasPagar']?['amanha'], Colors.orange),
                        _buildVencimentoRow('Até 3 dias', stats['contasPagar']?['em3Dias'], Colors.amber),
                        _buildVencimentoRow('Até 5 dias', stats['contasPagar']?['em5Dias'], Colors.blue),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Status Obras
              Expanded(
                flex: 2,
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Status de Conclusão Obras Ativas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Divider(),
                        if (stats['obras'] != null)
                          for (var obra in stats['obras'])
                            _buildObraProgress(obra),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Row 3: Últimas Transações
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Últimas Transações Registradas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(),
                  if (stats['ultimasTransacoes'] != null)
                    for (var t in stats['ultimasTransacoes'])
                      ListTile(
                        leading: Icon(
                          t['tipo'] == 'RECEITA' ? Icons.arrow_upward : Icons.arrow_downward,
                          color: t['tipo'] == 'RECEITA' ? Colors.green : Colors.red,
                        ),
                        title: Text(t['descricao'] ?? 'Sem descrição'),
                        subtitle: Text(t['categoria'] ?? ''),
                        trailing: Text(
                          formatCurrency.format(_parseValue(t['valor'])),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: t['tipo'] == 'RECEITA' ? Colors.green : Colors.red,
                          ),
                        ),
                      )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildVencimentoRow(String label, dynamic data, Color color) {
    final formatCurrency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final qtd = data?['qtd'] ?? 0;
    final valor = data?['valor'] ?? 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatCurrency.format(_parseValue(valor)), style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('$qtd docs', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }
  
  Widget _buildObraProgress(dynamic obra) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(obra['nome'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('${obra['progressoGeral'] ?? 0}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (obra['progressoGeral'] ?? 0) / 100,
            backgroundColor: Colors.grey.shade200,
            color: Colors.teal,
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: (obra['fases'] as List).map<Widget>((f) {
              return Expanded(
                child: Column(
                  children: [
                    Text(f['nome'], style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
                    Text('${f['progresso']}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey))),
                Icon(icon, color: color, size: 24),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

