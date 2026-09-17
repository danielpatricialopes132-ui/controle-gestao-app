import 'package:flutter_riverpod/flutter_riverpod.dart';

class TenantOverrideNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  
  void setTenant(String? tenantId) {
    state = tenantId;
  }
}

final tenantOverrideProvider = NotifierProvider<TenantOverrideNotifier, String?>(() {
  return TenantOverrideNotifier();
});
