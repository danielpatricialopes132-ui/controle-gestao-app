import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/api_client_provider.dart';

final aiProvider = AsyncNotifierProvider<AIController, void>(() {
  return AIController();
});

class AIController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<String?> sendMessage(String prompt, List<Map<String, String>> history) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.post('/ai/chat', {
        'prompt': prompt,
        'history': history,
      });
      state = const AsyncValue.data(null);
      return res['response'];
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}
