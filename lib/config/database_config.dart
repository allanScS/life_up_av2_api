import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';

/// Credenciais vêm do `.env` (ou de `DATABASE_URL` no Render).
class DatabaseConfig {
  DatabaseConfig({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
    required this.schema,
    required this.sslMode,
  });

  final String host;
  final int port;
  final String database;
  final String username;
  final String password;
  final String schema;
  final SslMode sslMode;

  factory DatabaseConfig.carregar({String caminho = '.env'}) {
    final envPath = _resolverArquivoEnv(caminho);
    final env = DotEnv(includePlatformEnvironment: true)..load([envPath]);

    final databaseUrl = env['DATABASE_URL'];
    if (databaseUrl != null && databaseUrl.trim().isNotEmpty) {
      return DatabaseConfig._fromUrl(databaseUrl, schema: env['DB_SCHEMA'] ?? 'lifeUpAv2');
    }

    final host = env['DB_HOST'];
    final portRaw = env['DB_PORT'];
    final database = env['DB_NAME'];
    final username = env['DB_USER'];
    final password = env['DB_PASSWORD'];
    final schema = env['DB_SCHEMA'] ?? 'lifeUpAv2';
    final sslRaw = (env['DB_SSL'] ?? 'require').toLowerCase();

    if (host == null || host.trim().isEmpty) {
      throw StateError('DB_HOST não configurado no .env ($envPath)');
    }
    if (portRaw == null || portRaw.trim().isEmpty) {
      throw StateError('DB_PORT não configurado no .env');
    }
    if (database == null || database.trim().isEmpty) {
      throw StateError('DB_NAME não configurado no .env');
    }
    if (username == null || username.trim().isEmpty) {
      throw StateError('DB_USER não configurado no .env');
    }
    if (password == null) {
      throw StateError('DB_PASSWORD não configurado no .env');
    }

    final port = int.tryParse(portRaw);
    if (port == null || port <= 0) {
      throw StateError('DB_PORT inválido: $portRaw');
    }

    return DatabaseConfig(
      host: host.trim(),
      port: port,
      database: database.trim(),
      username: username.trim(),
      password: password,
      schema: schema.trim().isEmpty ? 'lifeUpAv2' : schema.trim(),
      sslMode: _sslFrom(sslRaw),
    );
  }

  factory DatabaseConfig._fromUrl(String url, {required String schema}) {
    final uri = Uri.parse(url);
    final useSsl = uri.queryParameters['sslmode'] != 'disable';
    final userInfo = uri.userInfo;
    final username = userInfo.isEmpty ? '' : userInfo.split(':').first;
    final password = userInfo.contains(':')
        ? Uri.decodeComponent(userInfo.split(':').sublist(1).join(':'))
        : '';

    return DatabaseConfig(
      host: uri.host,
      port: uri.hasPort ? uri.port : 5432,
      database: uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'postgres',
      username: username,
      password: password,
      schema: schema.trim().isEmpty ? 'lifeUpAv2' : schema.trim(),
      sslMode: useSsl ? SslMode.require : SslMode.disable,
    );
  }

  static SslMode _sslFrom(String raw) {
    return switch (raw) {
      'disable' || 'false' || '0' => SslMode.disable,
      'verifyFull' || 'verify-full' => SslMode.verifyFull,
      _ => SslMode.require,
    };
  }

  static String _resolverArquivoEnv(String caminho) {
    final candidatos = <String>[
      caminho,
      'life_up_av2_api${Platform.pathSeparator}$caminho',
    ];

    try {
      final scriptFile = File.fromUri(Platform.script);
      final projetoDir = scriptFile.parent.parent;
      candidatos.add('${projetoDir.path}${Platform.pathSeparator}$caminho');
    } catch (_) {}

    for (final candidato in candidatos) {
      if (File(candidato).existsSync()) return candidato;
    }
    return caminho;
  }

  int? get portEnv => int.tryParse(
        Platform.environment['PORT'] ?? '',
      );
}
