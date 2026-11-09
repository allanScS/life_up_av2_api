import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../http/json_response.dart';
import '../repositories/habito_repository.dart';
import '../repositories/meta_repository.dart';
import '../repositories/registro_repository.dart';
import '../repositories/usuario_repository.dart';

class ApiRouter {
  ApiRouter({
    required this.usuarios,
    required this.habitos,
    required this.metas,
    required this.registros,
  });

  final UsuarioRepository usuarios;
  final HabitoRepository habitos;
  final MetaRepository metas;
  final RegistroRepository registros;

  Router get router {
    final r = Router();

    r.get('/', (Request request) {
      return jsonOk({
        'servico': 'life_up_av2_api',
        'tema': 'Monitoramento Pessoal & Hábitos',
        'docs': {
          'swagger': '/swagger',
          'openapi': '/openapi.yaml',
        },
        'health': '/health',
        'auth': ['POST /auth/register', 'POST /auth/login'],
        'recursos': [
          '/usuarios/:id/habitos',
          '/usuarios/:id/metas',
          '/usuarios/:id/registros',
          'POST /usuarios/:id/sync',
          'GET /usuarios/:id/backup',
        ],
      });
    });


    r.get('/health', (Request request) {
      return jsonOk({
        'status': 'ok',
        'servico': 'life_up_av2_api',
        'tema': 'Monitoramento Pessoal & Hábitos',
      });
    });


    r.post('/auth/register', _register);
    r.post('/auth/login', _login);

    r.get('/usuarios/<usuarioId>/habitos', _listarHabitos);
    r.post('/usuarios/<usuarioId>/habitos', _upsertHabito);
    r.put('/usuarios/<usuarioId>/habitos/<id>', _upsertHabitoPorId);
    r.delete('/usuarios/<usuarioId>/habitos/<id>', _removerHabito);

    r.get('/usuarios/<usuarioId>/metas', _listarMetas);
    r.post('/usuarios/<usuarioId>/metas', _upsertMeta);
    r.put('/usuarios/<usuarioId>/metas/<id>', _upsertMetaPorId);
    r.delete('/usuarios/<usuarioId>/metas/<id>', _removerMeta);

    r.get('/usuarios/<usuarioId>/registros', _listarRegistros);
    r.post('/usuarios/<usuarioId>/registros', _upsertRegistro);
    r.put('/usuarios/<usuarioId>/registros/<id>', _upsertRegistroPorId);
    r.delete('/usuarios/<usuarioId>/registros/<id>', _removerRegistro);

    /// Sync Offline-First: recebe lotes pendentes e devolve estado consolidado.
    r.post('/usuarios/<usuarioId>/sync', _sync);

    r.get('/usuarios/<usuarioId>/backup', _backup);

    return r;
  }

  Future<Response> _register(Request request) async {
    try {
      final body = await lerJson(request);
      final nome = (body['nome'] as String?)?.trim() ?? '';
      final nomeUsuario = (body['nome_usuario'] as String?)?.trim() ?? '';
      final senha = (body['senha'] as String?) ?? '';

      if (nome.isEmpty || nomeUsuario.length < 3 || senha.length < 4) {
        return jsonError(
          'Informe nome, nome_usuario (>=3) e senha (>=4).',
          status: 422,
        );
      }

      final existente = await usuarios.buscarPorNomeUsuario(nomeUsuario);
      if (existente != null) {
        return jsonError('Nome de usuário já existe.', status: 409);
      }

      final criado = await usuarios.cadastrar(
        nome: nome,
        nomeUsuario: nomeUsuario,
        senha: senha,
      );
      return jsonOk(usuarios.publico(criado), status: 201);
    } on FormatException catch (e) {
      return jsonError(e.message, status: 400);
    } catch (e) {
      return jsonError('Falha no cadastro.', status: 500, details: e.toString());
    }
  }

  Future<Response> _login(Request request) async {
    try {
      final body = await lerJson(request);
      final nomeUsuario = (body['nome_usuario'] as String?)?.trim() ?? '';
      final senha = (body['senha'] as String?) ?? '';

      final user = await usuarios.autenticar(
        nomeUsuario: nomeUsuario,
        senha: senha,
      );
      if (user == null) {
        return jsonError('Credenciais inválidas.', status: 401);
      }
      return jsonOk(usuarios.publico(user));
    } on FormatException catch (e) {
      return jsonError(e.message, status: 400);
    }
  }

  int? _parseUsuarioId(String raw) => int.tryParse(raw);

  Future<Response> _listarHabitos(Request request, String usuarioId) async {
    final uid = _parseUsuarioId(usuarioId);
    if (uid == null) return jsonError('usuarioId inválido', status: 400);
    final lista = await habitos.listarPorUsuario(uid);
    return jsonOk({'itens': lista});
  }

  Future<Response> _upsertHabito(Request request, String usuarioId) async {
    return _upsertHabitoInterno(request, usuarioId, null);
  }

  Future<Response> _upsertHabitoPorId(
    Request request,
    String usuarioId,
    String id,
  ) async {
    return _upsertHabitoInterno(request, usuarioId, id);
  }

  Future<Response> _upsertHabitoInterno(
    Request request,
    String usuarioId,
    String? idRota,
  ) async {
    final uid = _parseUsuarioId(usuarioId);
    if (uid == null) return jsonError('usuarioId inválido', status: 400);
    try {
      final body = await lerJson(request);
      if (idRota != null) body['id'] = idRota;
      body['usuario_id'] = uid;
      if ((body['nome'] as String?)?.trim().isEmpty ?? true) {
        return jsonError('nome é obrigatório', status: 422);
      }
      if (body['tipo'] == null) {
        return jsonError('tipo é obrigatório', status: 422);
      }
      final salvo = await habitos.upsert(body);
      return jsonOk(salvo);
    } catch (e) {
      return jsonError('Falha ao salvar hábito', status: 500, details: '$e');
    }
  }

  Future<Response> _removerHabito(
    Request request,
    String usuarioId,
    String id,
  ) async {
    final uid = _parseUsuarioId(usuarioId);
    if (uid == null) return jsonError('usuarioId inválido', status: 400);
    final ok = await habitos.remover(id, uid);
    if (!ok) return jsonError('Hábito não encontrado', status: 404);
    return jsonOk({'removido': true});
  }

  Future<Response> _listarMetas(Request request, String usuarioId) async {
    final uid = _parseUsuarioId(usuarioId);
    if (uid == null) return jsonError('usuarioId inválido', status: 400);
    return jsonOk({'itens': await metas.listarPorUsuario(uid)});
  }

  Future<Response> _upsertMeta(Request request, String usuarioId) async {
    return _upsertMetaInterno(request, usuarioId, null);
  }

  Future<Response> _upsertMetaPorId(
    Request request,
    String usuarioId,
    String id,
  ) async {
    return _upsertMetaInterno(request, usuarioId, id);
  }

  Future<Response> _upsertMetaInterno(
    Request request,
    String usuarioId,
    String? idRota,
  ) async {
    final uid = _parseUsuarioId(usuarioId);
    if (uid == null) return jsonError('usuarioId inválido', status: 400);
    try {
      final body = await lerJson(request);
      if (idRota != null) body['id'] = idRota;
      body['usuario_id'] = uid;
      final objetivo = (body['valor_objetivo'] as num?)?.toDouble() ?? 0;
      if (objetivo <= 0) {
        return jsonError('valor_objetivo deve ser > 0', status: 422);
      }
      if (body['tipo'] == null || body['titulo'] == null) {
        return jsonError('tipo e titulo são obrigatórios', status: 422);
      }
      return jsonOk(await metas.upsert(body));
    } catch (e) {
      return jsonError('Falha ao salvar meta', status: 500, details: '$e');
    }
  }

  Future<Response> _removerMeta(
    Request request,
    String usuarioId,
    String id,
  ) async {
    final uid = _parseUsuarioId(usuarioId);
    if (uid == null) return jsonError('usuarioId inválido', status: 400);
    final ok = await metas.remover(id, uid);
    if (!ok) return jsonError('Meta não encontrada', status: 404);
    return jsonOk({'removido': true});
  }

  Future<Response> _listarRegistros(Request request, String usuarioId) async {
    final uid = _parseUsuarioId(usuarioId);
    if (uid == null) return jsonError('usuarioId inválido', status: 400);
    return jsonOk({'itens': await registros.listarPorUsuario(uid)});
  }

  Future<Response> _upsertRegistro(Request request, String usuarioId) async {
    return _upsertRegistroInterno(request, usuarioId, null);
  }

  Future<Response> _upsertRegistroPorId(
    Request request,
    String usuarioId,
    String id,
  ) async {
    return _upsertRegistroInterno(request, usuarioId, id);
  }

  Future<Response> _upsertRegistroInterno(
    Request request,
    String usuarioId,
    String? idRota,
  ) async {
    final uid = _parseUsuarioId(usuarioId);
    if (uid == null) return jsonError('usuarioId inválido', status: 400);
    try {
      final body = await lerJson(request);
      if (idRota != null) body['id'] = idRota;
      body['usuario_id'] = uid;
      final valor = (body['valor'] as num?)?.toDouble() ?? 0;
      if (valor <= 0) {
        return jsonError('valor deve ser > 0', status: 422);
      }
      return jsonOk(await registros.upsert(body));
    } catch (e) {
      return jsonError('Falha ao salvar registro', status: 500, details: '$e');
    }
  }

  Future<Response> _removerRegistro(
    Request request,
    String usuarioId,
    String id,
  ) async {
    final uid = _parseUsuarioId(usuarioId);
    if (uid == null) return jsonError('usuarioId inválido', status: 400);
    final ok = await registros.remover(id, uid);
    if (!ok) return jsonError('Registro não encontrado', status: 404);
    return jsonOk({'removido': true});
  }

  Future<Response> _sync(Request request, String usuarioId) async {
    final uid = _parseUsuarioId(usuarioId);
    if (uid == null) return jsonError('usuarioId inválido', status: 400);

    try {
      final body = await lerJson(request);
      final habitosIn = (body['habitos'] as List?) ?? const [];
      final metasIn = (body['metas'] as List?) ?? const [];
      final registrosIn = (body['registros'] as List?) ?? const [];

      final habitosSync = <Map<String, dynamic>>[];
      for (final item in habitosIn) {
        final map = Map<String, dynamic>.from(item as Map);
        map['usuario_id'] = uid;
        habitosSync.add(await habitos.upsert(map));
      }

      final metasSync = <Map<String, dynamic>>[];
      for (final item in metasIn) {
        final map = Map<String, dynamic>.from(item as Map);
        map['usuario_id'] = uid;
        metasSync.add(await metas.upsert(map));
      }

      final registrosSync = <Map<String, dynamic>>[];
      for (final item in registrosIn) {
        final map = Map<String, dynamic>.from(item as Map);
        map['usuario_id'] = uid;
        registrosSync.add(await registros.upsert(map));
      }

      return jsonOk({
        'sincronizado_em': DateTime.now().toUtc().toIso8601String(),
        'recebidos': {
          'habitos': habitosSync.length,
          'metas': metasSync.length,
          'registros': registrosSync.length,
        },
        'habitos': await habitos.listarPorUsuario(uid),
        'metas': await metas.listarPorUsuario(uid),
        'registros': await registros.listarPorUsuario(uid),
      });
    } catch (e, st) {
      // ignora: log para diagnóstico local do 500
      // ignore: avoid_print
      print('SYNC ERROR usuario=$uid: $e\n$st');
      return jsonError('Falha na sincronização', status: 500, details: '$e');
    }
  }

  Future<Response> _backup(Request request, String usuarioId) async {
    final uid = _parseUsuarioId(usuarioId);
    if (uid == null) return jsonError('usuarioId inválido', status: 400);
    final user = await usuarios.buscarPorId(uid);
    if (user == null) return jsonError('Usuário não encontrado', status: 404);

    return jsonOk({
      'usuario': usuarios.publico(user),
      'habitos': await habitos.listarPorUsuario(uid),
      'metas': await metas.listarPorUsuario(uid),
      'registros': await registros.listarPorUsuario(uid),
      'gerado_em': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
