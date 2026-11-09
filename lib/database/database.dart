import 'package:postgres/postgres.dart';

import '../config/database_config.dart';

/// Abre conexão PostgreSQL a partir do `.env` / `DATABASE_URL`.
class Database {
  Database._(this.connection, this.config);

  final Connection connection;
  final DatabaseConfig config;

  String get schema => config.schema;

  static Future<Database> abrir({DatabaseConfig? config}) async {
    final cfg = config ?? DatabaseConfig.carregar();

    final connection = await Connection.open(
      Endpoint(
        host: cfg.host,
        port: cfg.port,
        database: cfg.database,
        username: cfg.username,
        password: cfg.password,
      ),
      settings: ConnectionSettings(sslMode: cfg.sslMode),
    );

    final db = Database._(connection, cfg);
    await db.migrar();
    return db;
  }

  Future<void> migrar() async {
    final schemaName = schema.replaceAll('"', '');
    await connection.execute('CREATE SCHEMA IF NOT EXISTS "$schemaName"');
    await connection.execute('SET search_path TO "$schemaName"');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS usuarios (
    id              SERIAL PRIMARY KEY,
    nome            VARCHAR(120) NOT NULL,
    nome_usuario    VARCHAR(80) NOT NULL UNIQUE,
    senha_hash      VARCHAR(255) NOT NULL,
    data_cadastro   TIMESTAMPTZ NOT NULL DEFAULT NOW()
)
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS habitos (
    id              VARCHAR(64) PRIMARY KEY,
    usuario_id      INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    nome            VARCHAR(120) NOT NULL,
    descricao       TEXT,
    tipo            VARCHAR(40) NOT NULL,
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    data_criacao    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em   TIMESTAMPTZ NOT NULL DEFAULT NOW()
)
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS metas (
    id              VARCHAR(64) PRIMARY KEY,
    usuario_id      INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    tipo            VARCHAR(20) NOT NULL,
    titulo          VARCHAR(160) NOT NULL,
    descricao       TEXT,
    valor_objetivo  NUMERIC(12, 2) NOT NULL,
    valor_atual     NUMERIC(12, 2) NOT NULL DEFAULT 0,
    status          VARCHAR(20) NOT NULL DEFAULT 'pendente',
    data_criacao    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_meta_usuario_tipo UNIQUE (usuario_id, tipo)
)
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS registros (
    id              VARCHAR(64) PRIMARY KEY,
    usuario_id      INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    habito_id       VARCHAR(64),
    valor           NUMERIC(12, 2) NOT NULL,
    observacao      TEXT,
    data_registro   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em   TIMESTAMPTZ NOT NULL DEFAULT NOW()
)
''');
  }

  Future<void> fechar() => connection.close();
}
