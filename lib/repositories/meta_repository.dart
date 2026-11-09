import 'package:postgres/postgres.dart';

import '../database/database.dart';

class MetaRepository {
  MetaRepository(this._db);

  final Database _db;
  Connection get _c => _db.connection;

  Future<List<Map<String, dynamic>>> listarPorUsuario(int usuarioId) async {
    final result = await _c.execute(
      Sql.named(
        'SELECT * FROM metas WHERE usuario_id = @uid ORDER BY data_criacao DESC',
      ),
      parameters: {'uid': usuarioId},
    );
    return result.map(_mapRow).toList();
  }

  Future<Map<String, dynamic>?> buscarPorId(String id) async {
    final result = await _c.execute(
      Sql.named('SELECT * FROM metas WHERE id = @id'),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return _mapRow(result.first);
  }

  Future<Map<String, dynamic>?> buscarPorUsuarioETipo(
    int usuarioId,
    String tipo,
  ) async {
    final result = await _c.execute(
      Sql.named(
        'SELECT * FROM metas WHERE usuario_id = @uid AND tipo = @tipo LIMIT 1',
      ),
      parameters: {'uid': usuarioId, 'tipo': tipo},
    );
    if (result.isEmpty) return null;
    return _mapRow(result.first);
  }

  /// Upsert por `id`. Se já existir outra meta do mesmo `(usuario_id, tipo)`,
  /// atualiza a canônica do servidor (evita 23505 em `uq_meta_usuario_tipo`).
  Future<Map<String, dynamic>> upsert(Map<String, dynamic> data) async {
    final id = data['id']?.toString();
    if (id == null || id.isEmpty) {
      throw ArgumentError('id da meta é obrigatório');
    }

    final usuarioId = _toInt(data['usuario_id']);
    final tipo = data['tipo']?.toString() ?? 'HIDRICA';

    final existenteTipo = await buscarPorUsuarioETipo(usuarioId, tipo);
    final targetId =
        (existenteTipo != null && existenteTipo['id']?.toString() != id)
            ? existenteTipo['id'].toString()
            : id;

    await _c.execute(
      Sql.named('''
INSERT INTO metas (
  id, usuario_id, tipo, titulo, descricao, valor_objetivo, valor_atual, status, data_criacao, atualizado_em
) VALUES (
  @id, @usuarioId, @tipo, @titulo, @descricao, @objetivo, @atual, @status, @dataCriacao, NOW()
)
ON CONFLICT (id) DO UPDATE SET
  titulo = EXCLUDED.titulo,
  descricao = EXCLUDED.descricao,
  valor_objetivo = EXCLUDED.valor_objetivo,
  valor_atual = EXCLUDED.valor_atual,
  status = EXCLUDED.status,
  atualizado_em = NOW()
'''),
      parameters: {
        'id': targetId,
        'usuarioId': usuarioId,
        'tipo': tipo,
        'titulo': data['titulo'],
        'descricao': data['descricao'],
        'objetivo': data['valor_objetivo'],
        'atual': data['valor_atual'] ?? 0,
        'status': data['status'] ?? 'pendente',
        'dataCriacao': _parseDate(data['data_criacao']) ?? DateTime.now().toUtc(),
      },
    );

    return (await buscarPorId(targetId))!;
  }

  Future<bool> remover(String id, int usuarioId) async {
    final result = await _c.execute(
      Sql.named('DELETE FROM metas WHERE id = @id AND usuario_id = @uid'),
      parameters: {'id': id, 'uid': usuarioId},
    );
    return result.affectedRows > 0;
  }

  Map<String, dynamic> _mapRow(ResultRow row) {
    final m = row.toColumnMap();
    return {
      'id': m['id'],
      'usuario_id': _toInt(m['usuario_id']),
      'tipo': m['tipo'],
      'titulo': m['titulo'],
      'descricao': m['descricao'],
      'valor_objetivo': _toDouble(m['valor_objetivo']),
      'valor_atual': _toDouble(m['valor_atual']),
      'status': m['status'],
      'data_criacao': (m['data_criacao'] as DateTime).toIso8601String(),
      'atualizado_em': (m['atualizado_em'] as DateTime).toIso8601String(),
    };
  }

  int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.parse(value.toString());
  }

  double _toDouble(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    return DateTime.tryParse(value.toString())?.toUtc();
  }
}
