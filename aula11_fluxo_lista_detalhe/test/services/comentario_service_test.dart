import 'dart:convert';

import 'package:aula11_fluxo_lista_detalhe/models/comentario_model.dart';
import 'package:aula11_fluxo_lista_detalhe/services/comentario_service.dart';
import 'package:aula11_fluxo_lista_detalhe/services/noticia_service.dart'
    show
        NoticiaFormatoException,
        NoticiaHttpException,
        NoticiaRedeException;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/api_fake.dart';

void main() {
  group('ComentarioService.buscarComentarios', () {
    test('converte a lista JSON em ComentarioModel (status 200)', () async {
      final ComentarioService service =
          ComentarioService(client: ApiFake.comentariosComSucesso(quantidade: 3));

      final List<ComentarioModel> comentarios =
          await service.buscarComentarios(7);

      expect(comentarios, hasLength(3));
      expect(comentarios.first, isA<ComentarioModel>());
      expect(comentarios[0].nome, 'Comentarista 1');
      expect(comentarios[0].email, 'comentarista1@example.com');
      expect(comentarios[0].texto, 'Comentário número 1 sobre a notícia.');
      expect(comentarios[0].noticiaId, 1);
    });

    test('usa o endpoint /posts/{id}/comments com o id informado', () async {
      http.Request? requisicao;
      final ComentarioService service = ComentarioService(
        client: MockClient((http.Request request) async {
          requisicao = request;
          return http.Response('[]', 200);
        }),
      );

      await service.buscarComentarios(42);

      expect(requisicao, isNotNull);
      expect(requisicao!.url.path, '/posts/42/comments');
      expect(requisicao!.method, 'GET');
    });

    test('lista vazia retorna lista vazia sem erro', () async {
      final ComentarioService service =
          ComentarioService(client: ApiFake.resposta(statusCode: 200, body: '[]'));

      expect(await service.buscarComentarios(1), isEmpty);
    });

    test('lança NoticiaHttpException quando statusCode != 200', () async {
      final ComentarioService service = ComentarioService(
        client: ApiFake.resposta(statusCode: 503, body: 'indisponível'),
      );

      await expectLater(
        service.buscarComentarios(1),
        throwsA(isA<NoticiaHttpException>()
            .having((NoticiaHttpException e) => e.statusCode, 'statusCode', 503)),
      );
    });

    test('lança NoticiaFormatoException para JSON inválido', () async {
      final ComentarioService service = ComentarioService(
        client: ApiFake.resposta(statusCode: 200, body: '{inválido'),
      );

      await expectLater(
        service.buscarComentarios(1),
        throwsA(isA<NoticiaFormatoException>()),
      );
    });

    test('lança NoticiaRedeException em falha de rede', () async {
      final ComentarioService service =
          ComentarioService(client: ApiFake.falhaDeRede());

      await expectLater(
        service.buscarComentarios(1),
        throwsA(isA<NoticiaRedeException>()),
      );
    });

    test('lança NoticiaRedeException no timeout', () async {
      final ComentarioService service = ComentarioService(
        client: ApiFake.respostaLenta(atraso: const Duration(seconds: 2)),
        timeout: const Duration(milliseconds: 50),
      );

      await expectLater(
        service.buscarComentarios(1),
        throwsA(isA<NoticiaRedeException>()),
      );
    });

    test('mapeia campos ausentes de forma defensiva', () async {
      final ComentarioService service = ComentarioService(
        client: ApiFake.resposta(
          statusCode: 200,
          body: jsonEncode(<Map<String, dynamic>>[
            <String, dynamic>{'id': 1, 'postId': 5},
          ]),
        ),
      );

      final List<ComentarioModel> comentarios =
          await service.buscarComentarios(5);

      expect(comentarios.single.nome, '');
      expect(comentarios.single.email, '');
      expect(comentarios.single.texto, '');
      expect(comentarios.single.noticiaId, 5);
    });
  });
}
