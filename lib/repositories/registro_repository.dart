import 'package:postgres/postgres.dart';

import '../database/database.dart';

class RegistroRepository {
  RegistroRepository(this._db);

  final Database _db;
  Connection get _c => _db.connection;

  Future<List<Map<String, dynamic>>> listarPorUsuario(int usuarioId) async {
    final result = await _c.execute(
      Sql.named(
        'SELECT * FROM registros WHERE usuario_id = @uid ORDER BY data_registro DESC',
      ),
      parameters: {'uid': usuarioId},
    );
    return result.map(_mapRow).toList();
  }

  Future<Map<String, dynamic>?> buscarPorId(String id) async {
    final result = await _c.execute(
      Sql.named('SELECT * FROM registros WHERE id = @id'),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return _mapRow(result.first);
  }

  Future<Map<String, dynamic>> upsert(Map<String, dynamic> data) async {
    final id = data['id']?.toString();
    if (id == null || id.isEmpty) {
      throw ArgumentError('id do registro é obrigatório');
    }

    await _c.execute(
      Sql.named('''
INSERT INTO registros (
  id, usuario_id, habito_id, valor, observacao, data_registro, atualizado_em
) VALUES (
  @id, @usuarioId, @habitoId, @valor, @observacao, @dataRegistro, NOW()
)
ON CONFLICT (id) DO UPDATE SET
  habito_id = EXCLUDED.habito_id,
  valor = EXCLUDED.valor,
  observacao = EXCLUDED.observacao,
  data_registro = EXCLUDED.data_registro,
  atualizado_em = NOW()
'''),
      parameters: {
        'id': id,
        'usuarioId': data['usuario_id'],
        'habitoId': data['habito_id'],
        'valor': data['valor'],
        'observacao': data['observacao'],
        'dataRegistro':
            _parseDate(data['data_registro']) ?? DateTime.now().toUtc(),
      },
    );

    return (await buscarPorId(id))!;
  }

  Future<bool> remover(String id, int usuarioId) async {
    final result = await _c.execute(
      Sql.named('DELETE FROM registros WHERE id = @id AND usuario_id = @uid'),
      parameters: {'id': id, 'uid': usuarioId},
    );
    return result.affectedRows > 0;
  }

  Map<String, dynamic> _mapRow(ResultRow row) {
    final m = row.toColumnMap();
    return {
      'id': m['id'],
      'usuario_id': m['usuario_id'] is num
          ? (m['usuario_id'] as num).toInt()
          : int.parse(m['usuario_id'].toString()),
      'habito_id': m['habito_id'],
      'valor': m['valor'] is num
          ? (m['valor'] as num).toDouble()
          : double.tryParse(m['valor'].toString()) ?? 0,
      'observacao': m['observacao'],
      'data_registro': (m['data_registro'] as DateTime).toIso8601String(),
      'atualizado_em': (m['atualizado_em'] as DateTime).toIso8601String(),
    };
  }

  DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    return DateTime.tryParse(value.toString())?.toUtc();
  }
}
