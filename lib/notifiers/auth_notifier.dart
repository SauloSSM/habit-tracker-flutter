import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../repositories/auth_repository.dart';
import '../services/validators.dart';

class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this.repository) : _user = repository.currentUser {
    _subscription = repository.userChanges.listen(
      (user) {
        if (busy) return;
        _user = user;
        notifyListeners();
      },
      onError: (_) {
        _user = null;
        error = 'Sua sessão foi interrompida. Entre novamente.';
        notifyListeners();
      },
    );
  }

  final AuthRepository repository;
  late final StreamSubscription<AppUser?> _subscription;
  AppUser? _user;
  AppUser? get user => _user;
  bool get isDemo => repository.isDemo;
  bool busy = false;
  String? error;
  String? recoveryMessage;

  Future<bool> _perform(Future<void> Function() action) async {
    if (busy) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      _user = repository.currentUser;
      return true;
    } on AuthFailure catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Não foi possível concluir. Tente novamente.';
    } finally {
      _user = repository.currentUser;
      busy = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> login(String email, String password) => _perform(() async {
    final validation =
        Validators.email(email) ?? Validators.requiredPassword(password);
    if (validation != null) throw AuthFailure(validation);
    await repository.login(email.trim().toLowerCase(), password);
  });

  Future<bool> register(
    String name,
    String email,
    String phone,
    String password,
  ) => _perform(() async {
    final validation =
        Validators.name(name) ??
        Validators.email(email) ??
        Validators.phone(phone) ??
        Validators.password(password);
    if (validation != null) throw AuthFailure(validation);
    await repository.register(
      name.trim(),
      email.trim().toLowerCase(),
      phone,
      password,
    );
  });

  Future<bool> updateName(String name) => _perform(() async {
    final validation = Validators.name(name);
    if (validation != null) throw AuthFailure(validation);
    await repository.updateName(name.trim());
  });

  Future<bool> recover(String email) => _perform(() async {
    recoveryMessage = null;
    final validation = Validators.email(email);
    if (validation != null) throw AuthFailure(validation);
    recoveryMessage = await repository.requestPasswordReset(
      email.trim().toLowerCase(),
    );
  });

  Future<bool> logout() => _perform(repository.logout);

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    unawaited(repository.dispose());
    super.dispose();
  }
}
