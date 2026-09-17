import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/api_client_provider.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

class AppUserNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;
  void updateState(Map<String, dynamic>? value) => state = value;
}
final appUserProvider = NotifierProvider<AppUserNotifier, Map<String, dynamic>?>(AppUserNotifier.new);

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Estado inicial
  }

  Future<Map<String, dynamic>> signInWithEmailAndPassword(String email, String password) async {
    state = const AsyncLoading();
    Map<String, dynamic> userData = {};

    state = await AsyncValue.guard(() async {
      final auth = ref.read(firebaseAuthProvider);
      await auth.signInWithEmailAndPassword(email: email, password: password);
      
      // Pequeno delay para garantir que o token esteja disponível
      await Future.delayed(const Duration(milliseconds: 500));

      final api = ref.read(apiClientProvider);
      final response = await api.get('/auth/sync');
      userData = response['user'];
      ref.read(appUserProvider.notifier).updateState(userData);
    });
    
    if (state.hasError) throw state.error!;
    return userData;
  }

  Future<Map<String, dynamic>> signUpWithEmailAndPassword(String email, String password) async {
    state = const AsyncLoading();
    Map<String, dynamic> userData = {};

    state = await AsyncValue.guard(() async {
      final auth = ref.read(firebaseAuthProvider);
      await auth.createUserWithEmailAndPassword(email: email, password: password);
      
      await Future.delayed(const Duration(milliseconds: 500));

      final api = ref.read(apiClientProvider);
      final response = await api.get('/auth/sync');
      userData = response['user'];
      ref.read(appUserProvider.notifier).updateState(userData);
    });
    
    if (state.hasError) throw state.error!;
    return userData;
  }

  Future<void> signOut() async {
    final auth = ref.read(firebaseAuthProvider);
    await auth.signOut();
    ref.read(appUserProvider.notifier).updateState(null);
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final auth = ref.read(firebaseAuthProvider);
      await auth.sendPasswordResetEmail(email: email);
    });
    if (state.hasError) throw state.error!;
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(() {
  return AuthController();
});


