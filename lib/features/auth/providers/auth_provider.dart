import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../../../core/database/database_helper.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    return DatabaseHelper().getLastUser();
  }

  Future<bool> signUp(String name, String email) async {
    state = const AsyncLoading();
    try {
      final existing = await DatabaseHelper().getUserByEmail(email);
      if (existing != null) {
        state = AsyncError('An account with this email already exists.', StackTrace.current);
        return false;
      }
      final user = UserModel(
        name: name,
        email: email,
        currency: 'USD',
        isOnboarded: false,
        createdAt: DateTime.now(),
      );
      final id = await DatabaseHelper().insertUser(user);
      state = AsyncData(user.copyWith(id: id));
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> signIn(String email) async {
    state = const AsyncLoading();
    try {
      final user = await DatabaseHelper().getUserByEmail(email);
      if (user == null) {
        state = AsyncError('No account found with this email.', StackTrace.current);
        return false;
      }
      state = AsyncData(user);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<void> updateUser(UserModel user) async {
    await DatabaseHelper().updateUser(user);
    state = AsyncData(user);
  }

  Future<void> completeOnboarding() async {
    final user = state.value;
    if (user == null) return;
    final updated = user.copyWith(isOnboarded: true);
    await DatabaseHelper().updateUser(updated);
    state = AsyncData(updated);
  }

  void signOut() {
    state = const AsyncData(null);
  }
}
