class Validators {
  static String? name(String? value) => (value ?? '').trim().length < 3
      ? 'Informe um nome com pelo menos 3 caracteres.'
      : null;

  static String? email(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Informe seu e-mail.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
      return 'Informe um e-mail válido.';
    }
    return null;
  }

  static String? phone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    return digits.length < 10 || digits.length > 13
        ? 'Informe um telefone com DDD (10 a 13 dígitos).'
        : null;
  }

  static String? password(String? value) =>
      (value ?? '').length < 8 ? 'Use pelo menos 8 caracteres.' : null;

  static String? requiredPassword(String? value) =>
      (value ?? '').isEmpty ? 'Informe sua senha.' : null;

  static String? title(String? value) =>
      (value ?? '').trim().isEmpty ? 'Dê um título ao hábito.' : null;
}
