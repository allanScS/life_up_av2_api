import 'package:postgres/postgres.dart';

import '../database/database.dart';

class HabitoRepository {
  HabitoRepository(this._db);

  final Database _db;
  Connection get _c => _db.connection;

  Future<List<Map<String, dynamic>>> listarPorUsuario(int usuarioId) async {
    final result = await _c.execute(
      Sql.named(
        'SELECT * FROM habitos WHERE usuario_id = @uid ORDER BY data_criacao DESC',
      ),
      parameters: {'uid': usuarioId},
    );
    return result.map(_mapRow).toList();
  }

  Future<Map<String, dynamic>?> buscarPorId(String id) async {
    final result = await _c.execute(
      Sql.named('SELECT * FROM habitos WHERE id = @id'),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return _mapRow(result.first);
  }

  Future<Map<String, dynamic>> upsert(Map<String, dynamic> data) async {
    final id = data['id']?.toString();
    if (id == null || id.isEmpty) {
      throw ArgumentError('id do hábito é obrigatório');
    }

    await _c.execute(
      Sql.named('''
INSERT INTO habitos (id, usuario_id, nome, descricao, tipo, ativo, data_criacao, atualizado_em)
VALUES (@id, @usuarioId, @nome, @descricao, @tipo, @ativo, @dataCriacao, NOW())
ON CONFLICT (id) DO UPDATE SET
  nome = EXCLUDED.nome,
  descricao = EXCLUDED.descricao,
  tipo = EXCLUDED.tipo,
  ativo = EXCLUDED.ativo,
  atualizado_em = NOW()
'''),
      parameters: {
        'id': id,
        'usuarioId': data['usuario_id'],
        'nome': data['nome'],
        'descricao': data['descricao'],
        'tipo': data['tipo'],
        'ativo': data['ativo'] ?? true,
        'dataCriacao': _parseDate(data['data_criacao']) ?? DateTime.now().toUtc(),
      },
    );

    return (await buscarPorId(id))!;
  }

  Future<bool> remover(String id, int usuarioId) async {
    final result = await _c.execute(
      Sql.named('DELETE FROM habitos WHERE id = @id AND usuario_id = @uid'),
      parameters: {'id': id, 'uid': usuarioId},
    );
    return result.affectedRows > 0;
  }

  Map<String, dynamic> _mapRow(ResultRow row) {
    final m = row.toColumnMap();
    return {
      'id': m['id'],
      'usuario_id': m['usuario_id'],
      'nome': m['nome'],
      'descricao': m['descricao'],
      'tipo': m['tipo'],
      'ativo': m['ativo'],
      'data_criacao': (m['data_criacao'] as DateTime).toIso8601String(),
      'atualizado_em': (m['atualizado_em'] as DateTime).toIso8601String(),
    };
  }

  DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    return DateTime.tryParse(value.toString())?.toUtc();
  }
}
