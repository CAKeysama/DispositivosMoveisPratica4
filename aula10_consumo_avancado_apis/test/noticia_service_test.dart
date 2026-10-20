import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:aula10_consumo_avancado_apis/models/noticia_model.dart';
import 'package:aula10_consumo_avancado_apis/services/noticia_service.dart';

void main() {
  group('NoticiaService.buscarNoticias', () {
    test('retorna lista em status 200 com JSON válido', () async {
      final mockJson = [
        {
          'id': 1,
          'userId': 1,
          'title': 'Título 1',
          'body': 'Corpo 1',
        },
        {
          'id': 2,
          'userId': 2,
          'title': 'Título 2',
          'body': 'Corpo 2',
        },
      ];

      final client = MockClient((request) async {
        return http.Response(jsonEncode(mockJson), 200);
      });

      final service = NoticiaService(client: client);
      final result = await service.buscarNoticias();

      expect(result, isA<List<NoticiaModel>>());
      expect(result.length, 2);
      expect(result.first.titulo, 'Título 1');
      expect(result.first.autorId, 1);
    });

    test('lança HttpException quando status diferente de 200', () async {
      final client = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final service = NoticiaService(client: client);

      expect(
        () => service.buscarNoticias(),
        throwsA(isA<HttpException>()),
      );
    });

    test('lança exceção em erro 500', () async {
      final client = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = NoticiaService(client: client);

      expect(
        () => service.buscarNoticias(),
        throwsA(isA<HttpException>()),
      );
    });

    test('retorna lista vazia quando JSON é lista vazia', () async {
      final client = MockClient((request) async {
        return http.Response('[]', 200);
      });

      final service = NoticiaService(client: client);
      final result = await service.buscarNoticias();

      expect(result, isEmpty);
    });

    test('lança FormatException quando JSON inválido', () async {
      final client = MockClient((request) async {
        return http.Response('não é json', 200);
      });

      final service = NoticiaService(client: client);

      expect(
        () => service.buscarNoticias(),
        throwsA(isA<FormatException>()),
      );
    });

    test('lança FormatException quando resposta não é lista', () async {
      final client = MockClient((request) async {
        return http.Response('{"id": 1}', 200);
      });

      final service = NoticiaService(client: client);

      expect(
        () => service.buscarNoticias(),
        throwsA(isA<FormatException>()),
      );
    });

    test('lança SocketException em erro de rede', () async {
      final client = MockClient((request) async {
        throw const SocketException('Failed host lookup');
      });

      final service = NoticiaService(client: client);

      expect(
        () => service.buscarNoticias(),
        throwsA(isA<SocketException>()),
      );
    });

    test('lança TimeoutException em timeout', () async {
      final client = MockClient((request) async {
        await Future.delayed(const Duration(seconds: 2));
        return http.Response('[]', 200);
      });

      final service = NoticiaService(client: client);

      expect(
        () => service.buscarNoticias(timeout: const Duration(milliseconds: 100)),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('simulação de falha usa URL inválida e gera erro', () async {
      final client = MockClient((request) async {
        // Verifica se URL contém marcador de simulação
        if (request.url.toString().contains('invalid')) {
          throw const SocketException('Failed host lookup');
        }
        return http.Response('[]', 200);
      });

      final service = NoticiaService(client: client);

      // Sem simulação deve funcionar
      final ok = await service.buscarNoticias(simularErro: false);
      expect(ok, isEmpty);

      // Com simulação deve falhar
      expect(
        () => service.buscarNoticias(simularErro: true),
        throwsA(isA<SocketException>()),
      );
    });

    test('verifica response.statusCode == 200 explicitamente', () async {
      // Teste de contrato: somente 200 é sucesso
      for (final code in [201, 204, 301, 400, 500]) {
        final client = MockClient((request) async {
          return http.Response('[]', code);
        });
        final service = NoticiaService(client: client);
        expect(
          () => service.buscarNoticias(),
          throwsA(isA<HttpException>()),
          reason: 'Código $code não deve ser tratado como sucesso',
        );
      }
    });

    test('recuperação após falha: segunda chamada com sucesso', () async {
      int callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          return http.Response('Error', 500);
        }
        return http.Response(
            jsonEncode([
              {
                'id': 1,
                'userId': 1,
                'title': 'Recuperado',
                'body': 'Corpo recuperado',
              }
            ]),
            200);
      });

      final service = NoticiaService(client: client);

      // Primeira falha
      expect(() => service.buscarNoticias(), throwsA(isA<HttpException>()));

      // Segunda sucesso (simula Tentar Novamente)
      final result = await service.buscarNoticias();
      expect(result.length, 1);
      expect(result.first.titulo, 'Recuperado');
    });
  });
}
