import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';

class RoleGuard extends ConsumerWidget {
  final List<String> allowedRoles;
  final Widget child;
  final Widget? fallback;

  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(appUserProvider);
    
    // Se ainda não carregou o usuário, ou se estiver nulo, consideramos que não tem acesso
    if (userData == null) {
      return fallback ?? const SizedBox.shrink();
    }

    final String userRole = userData['role'] ?? 'USER';

    // MASTER tem acesso irrestrito
    if (userRole == 'MASTER') {
      return child;
    }

    // Se o perfil do usuário atual estiver na lista de permitidos
    if (allowedRoles.contains(userRole)) {
      return child;
    }

    // Caso contrário, mostra fallback (ou vazio)
    return fallback ?? const SizedBox.shrink();
  }
}
