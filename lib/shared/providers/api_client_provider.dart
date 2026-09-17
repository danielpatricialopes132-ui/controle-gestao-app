import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/providers/tenant_provider.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final tenantOverride = ref.watch(tenantOverrideProvider);
  return ApiClient(auth, tenantOverride: tenantOverride);
});
