import 'package:flutter/services.dart';

/// Validações dos formulários de autenticação (mensagens em português).
class Validadores {
  Validadores._();

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  static bool emailValido(String? v) => _email.hasMatch((v ?? '').trim());

  static String? nomeCompleto(String? v) {
    final partes = (v ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return 'Informe seu nome completo';
    if (partes.length < 2 || partes.join().length < 4) return 'Informe nome e sobrenome';
    return null;
  }

  static String? email(String? v) {
    if ((v ?? '').trim().isEmpty) return 'Informe seu e-mail';
    if (!emailValido(v)) return 'Informe um e-mail válido';
    return null;
  }

  /// Telefone é opcional; se preenchido precisa ter DDD + 8 ou 9 dígitos.
  static String? telefoneOpcional(String? v) {
    final digitos = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) return null;
    if (digitos.length < 10 || digitos.length > 11) return 'Informe o telefone com DDD';
    return null;
  }

  static String? senhaNova(String? v) {
    if ((v ?? '').isEmpty) return 'Crie uma senha';
    if (v!.length < 8) return 'A senha precisa ter pelo menos 8 caracteres';
    return null;
  }

  static String? confirmacao(String? v, String senha) {
    if ((v ?? '').isEmpty) return 'Confirme sua senha';
    if (v != senha) return 'As senhas não coincidem';
    return null;
  }

  static String? senhaLogin(String? v) {
    if ((v ?? '').isEmpty) return 'Informe sua senha';
    return null;
  }
}

/// Máscara simples: (11) 98765-4321.
class TelefoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue antigo, TextEditingValue novo) {
    var d = novo.text.replaceAll(RegExp(r'\D'), '');
    if (d.length > 11) d = d.substring(0, 11);
    final b = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 0) b.write('(');
      if (i == 2) b.write(') ');
      final corte = d.length > 10 ? 7 : 6;
      if (i == corte) b.write('-');
      b.write(d[i]);
    }
    final texto = b.toString();
    return TextEditingValue(text: texto, selection: TextSelection.collapsed(offset: texto.length));
  }
}
