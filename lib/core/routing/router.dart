import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/select_tenant_screen.dart';
import '../../features/financeiro/presentation/financeiro_screen.dart';
import '../../features/financeiro/presentation/configuracao_contabil_screen.dart';
import '../../features/relatorios/presentation/relatorios_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/financeiro/presentation/calculadora/calculadora_financeira_screen.dart';
import '../../features/portal_cliente/presentation/screens/portal_cliente_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/financeiro',
      builder: (context, state) => const FinanceiroScreen(),
    ),
    GoRoute(
      path: '/configuracao-contabil',
      builder: (context, state) => const ConfiguracaoContabilScreen(),
    ),
    GoRoute(
      path: '/calculadora-financeira',
      builder: (context, state) => const CalculadoraFinanceiraScreen(),
    ),
    GoRoute(
      path: '/select-tenant',
      builder: (context, state) => const SelectTenantScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/portal-cliente',
      builder: (context, state) => const PortalClienteScreen(),
    ),
  ],
);
