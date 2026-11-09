import 'dart:convert';

import 'package:crypto/crypto.dart';

class SenhaUtil {
  static String gerarHash(String senha) {
    final bytes = utf8.encode(senha);
    return sha256.convert(bytes).toString();
  }

  static bool verificar(String senha, String hash) {
    return gerarHash(senha) == hash;
  }
}
