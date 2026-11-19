import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : auth = auth ?? FirebaseAuth.instance,
      firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  AppUser? _profileUser;

  AppUser? _map(User? user) => user == null
      ? null
      : _profileUser?.id == user.uid
      ? _profileUser
      : AppUser(
          id: user.uid,
          name: user.displayName ?? '',
          email: user.email ?? '',
        );

  @override
  bool get isDemo => false;
  @override
  AppUser? get currentUser => _map(auth.currentUser);
  @override
  Stream<AppUser?> get userChanges => auth.userChanges().map(_map);

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (e) {
      throw AuthFailure(messageFor(e.code));
    }
  }

  static String messageFor(String code) => switch (code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'E-mail ou senha incorretos.',
    'email-already-in-use' =>
      'Este e-mail já está cadastrado. Entre ou recupere sua senha.',
    'weak-password' => 'A senha não atende à política de segurança do projeto.',
    'invalid-email' => 'Informe um e-mail válido.',
    'too-many-requests' => 'Muitas tentativas. Aguarde e tente novamente.',
    'network-request-failed' || 'unavailable' =>
      'Sem conexão com o Firebase. Verifique sua internet e tente novamente.',
    'operation-not-allowed' =>
      'Login por e-mail/senha não está habilitado no Firebase.',
    'user-disabled' => 'Esta conta foi desativada.',
    'permission-denied' =>
      'Acesso ao perfil negado. Verifique as regras do Firestore.',
    _ => 'Não foi possível concluir. Tente novamente.',
  };

  @override
  Future<void> login(String email, String password) => _guard(() async {
    await auth.signInWithEmailAndPassword(email: email, password: password);
    // Repair a profile whose creation was interrupted after Auth succeeded.
    final user = auth.currentUser!;
    final ref = firestore.collection('usuarios').doc(user.uid);
    try {
      final data = await firestore.runTransaction((tx) async {
        final profile = await tx.get(ref);
        if (!profile.exists) {
          final data = _profile(user, user.displayName ?? 'Usuário', '');
          tx.set(ref, data);
          return data;
        }
        return profile.data()!;
      });
      _profileUser = AppUser(
        id: user.uid,
        name: data['nome'] as String,
        email: user.email!,
        phone: data['telefone'] as String,
      );
      if (user.displayName != _profileUser!.name) {
        await user.updateDisplayName(_profileUser!.name);
      }
    } catch (_) {
      await auth.signOut();
      rethrow;
    }
  });

  Map<String, dynamic> _profile(User user, String name, String phone) => {
    'uid': user.uid,
    'nome': name,
    'telefone': phone,
    'email': user.email,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  @override
  Future<void> register(
    String name,
    String email,
    String phone,
    String password,
  ) => _guard(() async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    try {
      await firestore
          .collection('usuarios')
          .doc(user.uid)
          .set(_profile(user, name, phone));
    } catch (_) {
      // Auth and Firestore have no shared transaction. Compensate a failed
      // profile write by removing the newly created Auth account when possible.
      try {
        await user.delete();
      } catch (_) {
        // If compensation also fails, login repairs the missing profile.
      } finally {
        await auth.signOut();
      }
      rethrow;
    }
    _profileUser = AppUser(
      id: user.uid,
      name: name,
      email: email,
      phone: phone,
    );
    await user.updateDisplayName(name);
  });

  @override
  Future<void> updateName(String name) => _guard(() async {
    final user = auth.currentUser;
    if (user == null) throw const AuthFailure('Entre na sua conta novamente.');
    await firestore.collection('usuarios').doc(user.uid).update({
      'nome': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _profileUser = AppUser(
      id: user.uid,
      name: name,
      email: user.email!,
      phone: _profileUser?.phone ?? '',
    );
    await user.updateDisplayName(name);
  });

  @override
  Future<String> requestPasswordReset(String email) => _guard(() async {
    await auth.sendPasswordResetEmail(email: email);
    return 'Se houver uma conta para este e-mail, você receberá as instruções de recuperação. Confira também o spam.';
  });

  @override
  Future<void> logout() => _guard(() async {
    await auth.signOut();
    _profileUser = null;
  });
  @override
  Future<void> dispose() async {}
}
