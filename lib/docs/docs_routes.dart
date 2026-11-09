import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// Swagger UI + OpenAPI (arquivos em `public/`).
class DocsRoutes {
  Router get router {
    final r = Router();

    r.get('/swagger', _swaggerHtml);
    r.get('/swagger/', _swaggerHtml);
    r.get('/docs', (_) => Response.found('/swagger'));
    r.get('/docs/', (_) => Response.found('/swagger'));
    r.get('/openapi.yaml', _openapiYaml);
    r.get('/openapi.json', _openapiYaml); // alias; conteúdo YAML

    return r;
  }

  Future<Response> _swaggerHtml(Request request) async {
    final file = await _localizar('swagger.html');
    if (file == null) {
      return Response.notFound('swagger.html não encontrado');
    }
    return Response.ok(
      await file.readAsString(),
      headers: {'content-type': 'text/html; charset=utf-8'},
    );
  }

  Future<Response> _openapiYaml(Request request) async {
    final file = await _localizar('openapi.yaml');
    if (file == null) {
      return Response.notFound('openapi.yaml não encontrado');
    }
    return Response.ok(
      await file.readAsString(),
      headers: {
        'content-type': 'application/yaml; charset=utf-8',
        'cache-control': 'no-cache',
      },
    );
  }

  Future<File?> _localizar(String nome) async {
    final sep = Platform.pathSeparator;
    final candidatos = <String>[
      'public$sep$nome',
      'life_up_av2_api${sep}public$sep$nome',
      '/app/public/$nome', // container Render/Docker
      '${Directory.current.path}${sep}public$sep$nome',
    ];

    try {
      final script = File.fromUri(Platform.script);
      final root = script.parent.parent; // .../life_up_av2_api
      candidatos.add('${root.path}${sep}public$sep$nome');
      // bundle AOT: bin/ -> ../public
      candidatos.add('${script.parent.parent.path}${sep}public$sep$nome');
    } catch (_) {}

    for (final path in candidatos) {
      final file = File(path);
      if (await file.exists()) return file;
    }
    return null;
  }
}

