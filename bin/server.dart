import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:life_up_av2_api/config/database_config.dart';
import 'package:life_up_av2_api/database/database.dart';
import 'package:life_up_av2_api/docs/docs_routes.dart';
import 'package:life_up_av2_api/repositories/habito_repository.dart';
import 'package:life_up_av2_api/repositories/meta_repository.dart';
import 'package:life_up_av2_api/repositories/registro_repository.dart';
import 'package:life_up_av2_api/repositories/usuario_repository.dart';
import 'package:life_up_av2_api/routes/api_router.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

Future<void> main(List<String> args) async {
  stdout.writeln('LifeUp AV2 API — iniciando...');

  final config = DatabaseConfig.carregar();
  final db = await Database.abrir(config: config);
  stdout.writeln('PostgreSQL conectado (schema ${config.schema}).');

  final api = ApiRouter(
    usuarios: UsuarioRepository(db),
    habitos: HabitoRepository(db),
    metas: MetaRepository(db),
    registros: RegistroRepository(db),
  );

  final docs = DocsRoutes();

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(
        Cascade().add(docs.router.call).add(api.router.call).handler,
      );

  final env = DotEnv(includePlatformEnvironment: true)..load(['.env']);
  final ip = InternetAddress.anyIPv4;
  final port = int.parse(env['PORT'] ?? Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);

  stdout.writeln('Servidor em http://${server.address.host}:${server.port}');
  stdout.writeln('Swagger: http://localhost:${server.port}/swagger');
  stdout.writeln('OpenAPI: http://localhost:${server.port}/openapi.yaml');
  stdout.writeln('Health:  http://localhost:${server.port}/health');
}
