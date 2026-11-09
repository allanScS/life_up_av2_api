import 'package:postgres/postgres.dart';

import '../database/database.dart';
import '../utils/senha_util.dart';

class UsuarioRepository {
  UsuarioRepository(this._db);

  final Database _db;

  Connection get _c => _db.connection;

  Future<Map<String, dynamic>?> buscarPorNomeUsuario(String nomeUsuario) async {
    final result = await _c.execute(
      Sql.named(
        'SELECT id, nome, nome_usuario, senha_hash, data_cadastro '
        'FROM usuarios WHERE nome_usuario = @nome',
      ),
      parameters: {'nome': nomeUsuario.trim().toLowerCase()},
    );
    if (result.isEmpty) return null;
    return _mapRow(result.first);
  }

  Future<Map<String, dynamic>?> buscarPorId(int id) async {
    final result = await _c.execute(
      Sql.named(
        'SELECT id, nome, nome_usuario, senha_hash, data_cadastro '
        'FROM usuarios WHERE id = @id',
      ),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return _mapRow(result.first);
  }

  Future<Map<String, dynamic>> cadastrar({
    required String nome,
    required String nomeUsuario,
    required String senha,
  }) async {
    final hash = SenhaUtil.gerarHash(senha);
    final result = await _c.execute(
      Sql.named(
        'INSERT INTO usuarios (nome, nome_usuario, senha_hash) '
        'VALUES (@nome, @nomeUsuario, @hash) '
        'RETURNING id, nome, nome_usuario, senha_hash, data_cadastro',
      ),
      parameters: {
        'nome': nome.trim(),
        'nomeUsuario': nomeUsuario.trim().toLowerCase(),
        'hash': hash,
      },
    );
    return _mapRow(result.first);
  }

  Future<Map<String, dynamic>?> autenticar({
    required String nomeUsuario,
    required String senha,
  }) async {
    final user = await buscarPorNomeUsuario(nomeUsuario);
    if (user == null) return null;
    if (!SenhaUtil.verificar(senha, user['senha_hash'] as String)) {
      return null;
    }
    return user;
  }

  Map<String, dynamic> _mapRow(ResultRow row) {
    final map = row.toColumnMap();
    return {
      'id': map['id'],
      'nome': map['nome'],
      'nome_usuario': map['nome_usuario'],
      'senha_hash': map['senha_hash'],
      'data_cadastro': (map['data_cadastro'] as DateTime).toIso8601String(),
    };
  }

  Map<String, dynamic> publico(Map<String, dynamic> user) {
    return {
      'id': user['id'],
      'nome': user['nome'],
      'nome_usuario': user['nome_usuario'],
      'data_cadastro': user['data_cadastro'],
    };
  }
}
