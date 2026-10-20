import 'dart:convert';

import 'package:aula11_fluxo_lista_detalhe/models/noticia_model.dart';
import 'package:aula11_fluxo_lista_detalhe/services/noticia_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/api_fake.dart';

void main() {
  group('NoticiaService.buscarNoticias', () {
    test(
      'converte a lista JSON em objetos NoticiaModel (status 200)',
      () async {
        final NoticiaService service = NoticiaService(
          client: ApiFake.noticiasComSucesso(quantidade: 3),
        );

        final List<NoticiaModel> noticias = await service.buscarNoticias();

        expect(noticias, hasLength(3));
        expect(noticias.first, isA<NoticiaModel>());
        expect(noticias[0].id, 1);
        expect(noticias[0].titulo, 'Título da notícia 1');
        expect(noticias[0].autor, 'Autor ID 11');
        expect(
          noticias[0].urlImagem,
          'https://picsum.photos/seed/post_1/1200/600',
        );
        expect(noticias[2].id, 3);
      },
    );

    test('respeita o mapeamento resumo/conteúdoCompleto', () async {
      final NoticiaService service = NoticiaService(
        client: ApiFake.resposta(
          statusCode: 200,
          body: jsonEncode(<Map<String, dynamic>>[
            <String, dynamic>{
              'id': 1,
              'userId': 1,
              'title': 'T',
              'body': 'Z' * 80,
            },
          ]),
        ),
      );

      final List<NoticiaModel> noticias = await service.buscarNoticias();

      expect(noticias.single.resumo, '${'Z' * 40}...');
      expect(noticias.single.conteudoCompleto, 'Z' * 80);
    });

    test('lança NoticiaHttpException quando statusCode != 200', () async {
      final NoticiaService service = NoticiaService(
        client: ApiFake.resposta(statusCode: 500, body: 'erro interno'),
      );

      await expectLater(
        service.buscarNoticias(),
        throwsA(
          isA<NoticiaHttpException>()
              .having(
                (NoticiaHttpException e) => e.statusCode,
                'statusCode',
                500,
              )
              .having(
                (NoticiaHttpException e) => e.mensagem,
                'mensagem',
                contains('500'),
              ),
        ),
      );
    });

    test('lança NoticiaHttpException também para 404', () async {
      final NoticiaService service = NoticiaService(
        client: ApiFake.resposta(statusCode: 404, body: 'não encontrado'),
      );

      await expectLater(
        service.buscarNoticias(),
        throwsA(isA<NoticiaHttpException>()),
      );
    });

    test('lança NoticiaFormatoException para JSON inválido', () async {
      final NoticiaService service = NoticiaService(
        client: ApiFake.resposta(statusCode: 200, body: 'não é json'),
      );

      await expectLater(
        service.buscarNoticias(),
        throwsA(isA<NoticiaFormatoException>()),
      );
    });

    test(
      'lança NoticiaFormatoException quando a resposta não é uma lista',
      () async {
        final NoticiaService service = NoticiaService(
          client: ApiFake.resposta(
            statusCode: 200,
            body: jsonEncode(<String, dynamic>{'id': 1}),
          ),
        );

        await expectLater(
          service.buscarNoticias(),
          throwsA(isA<NoticiaFormatoException>()),
        );
      },
    );

    test('lança NoticiaRedeException em falha de rede', () async {
      final NoticiaService service = NoticiaService(
        client: ApiFake.falhaDeRede(),
      );

      await expectLater(
        service.buscarNoticias(),
        throwsA(isA<NoticiaRedeException>()),
      );
    });

    test('lança NoticiaRedeException no timeout', () async {
      final NoticiaService service = NoticiaService(
        client: ApiFake.respostaLenta(atraso: const Duration(seconds: 2)),
        timeout: const Duration(milliseconds: 50),
      );

      await expectLater(
        service.buscarNoticias(),
        throwsA(isA<NoticiaRedeException>()),
      );
    });

    test('ignora elementos que não são mapas na lista', () async {
      final NoticiaService service = NoticiaService(
        client: ApiFake.resposta(
          statusCode: 200,
          body: jsonEncode(<Object?>[
            <String, dynamic>{'id': 1, 'userId': 1, 'title': 'A', 'body': 'a'},
            'não é mapa',
            null,
            <String, dynamic>{'id': 2, 'userId': 2, 'title': 'B', 'body': 'b'},
          ]),
        ),
      );

      final List<NoticiaModel> noticias = await service.buscarNoticias();
      expect(noticias, hasLength(2));
    });

    test('lista vazia retorna lista vazia sem erro', () async {
      final NoticiaService service = NoticiaService(
        client: ApiFake.resposta(statusCode: 200, body: '[]'),
      );

      final List<NoticiaModel> noticias = await service.buscarNoticias();
      expect(noticias, isEmpty);
    });

    test('usa o endpoint configurado', () async {
      http.Request? requisicao;
      final NoticiaService service = NoticiaService(
        client: MockClient((http.Request request) async {
          requisicao = request;
          return http.Response('[]', 200);
        }),
        endpoint: 'https://exemplo.teste/posts',
      );

      await service.buscarNoticias();

      expect(requisicao, isNotNull);
      expect(requisicao!.url.toString(), 'https://exemplo.teste/posts');
      expect(requisicao!.method, 'GET');
    });
  });
}
