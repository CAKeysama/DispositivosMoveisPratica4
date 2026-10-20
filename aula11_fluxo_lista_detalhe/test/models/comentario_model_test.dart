import 'package:aula11_fluxo_lista_detalhe/models/comentario_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ComentarioModel.fromJson', () {
    test('mapeia os campos da API para o modelo', () {
      final ComentarioModel comentario =
          ComentarioModel.fromJson(<String, dynamic>{
        'id': 11,
        'postId': 4,
        'name': 'Maria',
        'email': 'maria@example.com',
        'body': 'Ótima notícia!',
      });

      expect(comentario.id, 11);
      expect(comentario.noticiaId, 4);
      expect(comentario.nome, 'Maria');
      expect(comentario.email, 'maria@example.com');
      expect(comentario.texto, 'Ótima notícia!');
    });

    test('trata campos ausentes de forma defensiva', () {
      final ComentarioModel comentario =
          ComentarioModel.fromJson(<String, dynamic>{});

      expect(comentario.id, 0);
      expect(comentario.noticiaId, 0);
      expect(comentario.nome, '');
      expect(comentario.email, '');
      expect(comentario.texto, '');
    });

    test('trata tipos inválidos sem lançar exceção', () {
      final ComentarioModel comentario =
          ComentarioModel.fromJson(<String, dynamic>{
        'id': 'x',
        'postId': true,
        'name': 123,
        'email': 456,
        'body': null,
      });

      expect(comentario.id, 0);
      expect(comentario.noticiaId, 0);
      expect(comentario.nome, '');
      expect(comentario.email, '');
      expect(comentario.texto, '');
    });

    test('remove espaços extras das bordas dos textos', () {
      final ComentarioModel comentario =
          ComentarioModel.fromJson(<String, dynamic>{
        'id': 1,
        'postId': 1,
        'name': '  Ana  ',
        'email': ' ana@example.com ',
        'body': '  texto  ',
      });

      expect(comentario.nome, 'Ana');
      expect(comentario.email, 'ana@example.com');
      expect(comentario.texto, 'texto');
    });

    test('toJson preserva os principais campos', () {
      final ComentarioModel comentario = ComentarioModel(
        id: 1,
        nome: 'Ana',
        email: 'ana@example.com',
        texto: 'texto',
        noticiaId: 2,
      );

      expect(comentario.toJson(), <String, dynamic>{
        'id': 1,
        'postId': 2,
        'name': 'Ana',
        'email': 'ana@example.com',
        'body': 'texto',
      });
    });
  });
}
