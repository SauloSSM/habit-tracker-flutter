import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../models/app_user.dart';
import 'auth_repository.dart';

/// Repositório de teste acadêmico. Contas e verificadores vivem só na memória.
class DemoAuthRepository implements AuthRepository {
  DemoAuthRepository() {
    _addAccount('Estudante', demoEmail, demoPassword);
  }

  static const demoEmail = 'estudante@habit.local';
  static const demoPassword = 'Habito123!';
  final _changes = StreamController<AppUser?>.broadcast(sync: true);
  final Map<String, ({AppUser user, String salt, String digest})> _accounts =
      {};
  AppUser? _user;

  String _digest(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  void _addAccount(String name, String email, String password) {
    final salt = List.generate(
      24,
      (_) => Random.secure().nextInt(256),
    ).join('-');
    _accounts[email] = (
      user: AppUser(
        id: 'demo-${sha256.convert(utf8.encode(email))}',
        name: name,
        email: email,
      ),
      salt: salt,
      digest: _digest(salt, password),
    );
  }

  @override
  bool get isDemo => true;
  @override
  AppUser? get currentUser => _user;
  @override
  Stream<AppUser?> get userChanges => _changes.stream;

  @override
  Future<void> login(String email, String password) async {
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.digest != _digest(account.salt, password)) {
      throw const AuthFailure('E-mail ou senha incorretos.');
    }
    _changes.add(_user = account.user);
  }

  @override
  Future<void> register(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw const AuthFailure('Este e-mail já está cadastrado nesta sessão.');
    }
    _addAccount(name.trim(), key, password);
    _changes.add(_user = _accounts[key]!.user);
  }

  @override
  Future<void> updateName(String name) async {
    if (_user == null) throw const AuthFailure('Entre na sua conta novamente.');
    final account = _accounts[_user!.email]!;
    _user = _user!.withName(name.trim());
    _accounts[_user!.email] = (
      user: _user!,
      salt: account.salt,
      digest: account.digest,
    );
    _changes.add(_user);
  }

  @override
  Future<String> requestPasswordReset(String email) async =>
      'Simulação concluída. Nenhum e-mail foi enviado. '
      'Neste modo, use a conta de exemplo ou crie outra conta.';

  @override
  Future<void> logout() async => _changes.add(_user = null);

  @override
  Future<void> dispose() => _changes.close();
}
