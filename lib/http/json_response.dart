import 'dart:convert';

import 'package:shelf/shelf.dart';

Response jsonOk(Object? body, {int status = 200}) {
  return Response(
    status,
    body: jsonEncode(body),
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

Response jsonError(String message, {int status = 400, Object? details}) {
  return jsonOk(
    {
      'erro': message,
      if (details != null) 'detalhes': details,
    },
    status: status,
  );
}

Future<Map<String, dynamic>> lerJson(Request request) async {
  final raw = await request.readAsString();
  if (raw.trim().isEmpty) return {};
  final decoded = jsonDecode(raw);
  if (decoded is Map<String, dynamic>) return decoded;
  if (decoded is Map) return Map<String, dynamic>.from(decoded);
  throw const FormatException('JSON deve ser um objeto.');
}
