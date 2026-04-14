import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

/// In-memory store (replace with Redis / cloud DB for production scale).
final List<Map<String, dynamic>> _providers = [];

Map<String, String> get _cors => {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    };

Middleware _corsMiddleware() {
  return (Handler inner) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _cors);
      }
      final response = await inner(request);
      return response.change(headers: {..._cors, ...response.headers});
    };
  };
}

void _seedDemo() {
  if (_providers.isNotEmpty) return;
  _providers.addAll([
    {
      'id': 'demo-1',
      'providerName': 'DashRunner',
      'serviceName': 'Fast Grocery Delivery',
      'description':
          'Express grocery and essentials delivery around your area.',
      'latitude': 22.2855,
      'longitude': 114.1577,
      'priceMin': 8,
      'priceMax': 40,
      'rating': 4.8,
    },
    {
      'id': 'demo-2',
      'providerName': 'Spark Pro Team',
      'serviceName': 'Home Cleaning',
      'description':
          'Apartment and house cleaning with verified professionals.',
      'latitude': 22.3048,
      'longitude': 114.1722,
      'priceMin': 22,
      'priceMax': 120,
      'rating': 4.7,
    },
  ]);
}

void main() async {
  _seedDemo();

  final router = Router();

  router.get('/health', (Request request) {
    return Response.ok(
      jsonEncode({'status': 'ok', 'service': 'goservice-api'}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.get('/api/providers', (Request request) {
    return Response.ok(
      jsonEncode(_providers),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.post('/api/providers', (Request request) async {
    try {
      final body = await request.readAsString();
      if (body.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Empty body'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      final data = jsonDecode(body);
      if (data is! Map<String, dynamic>) {
        return Response.badRequest(
          body: jsonEncode({'error': 'JSON object required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      data['id'] = id;
      _providers.add(Map<String, dynamic>.from(data));
      return Response.ok(
        jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.badRequest(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  final handler = Pipeline()
      .addMiddleware(_corsMiddleware())
      .addMiddleware(logRequests())
      .addHandler(router.call);

  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  // ignore: avoid_print
  print('goservice-api listening on http://${server.address.host}:${server.port}');
}
