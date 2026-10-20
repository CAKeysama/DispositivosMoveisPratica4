import 'package:aula11_fluxo_lista_detalhe/models/noticia_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NoticiaModel.fromJson', () {
    test('mapeia os campos da API para o modelo', () {
      final NoticiaModel noticia = NoticiaModel.fromJson(<String, dynamic>{
        'id': 7,
        'userId': 3,
        'title': 'Título de teste',
        'body': 'Corpo da notícia com mais de quarenta caracteres no texto.',
      });

      expect(noticia.id, 7);
      expect(noticia.titulo, 'Título de teste');
      expect(
        noticia.conteudoCompleto,
        'Corpo da notícia com mais de quarenta caracteres no texto.',
      );
      expect(noticia.autor, 'Autor ID 3');
      expect(noticia.urlImagem, 'https://picsum.photos/seed/post_7/1200/600');
      expect(noticia.dataPublicacao, isNull);
    });

    test('resumo usa os primeiros 40 caracteres do corpo', () {
      final String corpo = 'A' * 100;
      final NoticiaModel noticia = NoticiaModel.fromJson(<String, dynamic>{
        'id': 1,
        'userId': 1,
        'title': 'T',
        'body': corpo,
      });

      expect(noticia.resumo.length, 43); // 40 caracteres + '...'
      expect(noticia.resumo, '${'A' * 40}...');
      expect(noticia.conteudoCompleto.length, 100);
    });

    test(
      'resumo de texto com exatamente 40 caracteres não ganha reticências',
      () {
        final String corpo = 'B' * 40;
        final NoticiaModel noticia = NoticiaModel.fromJson(<String, dynamic>{
          'id': 2,
          'userId': 1,
          'title': 'T',
          'body': corpo,
        });

        expect(noticia.resumo, corpo);
        expect(noticia.resumo.length, 40);
      },
    );

    test('texto menor que 40 caracteres não gera erro de substring', () {
      final NoticiaModel noticia = NoticiaModel.fromJson(<String, dynamic>{
        'id': 3,
        'userId': 1,
        'title': 'T',
        'body': 'Curto',
      });

      expect(noticia.resumo, 'Curto');
    });

    test('corpo vazio também não gera erro', () {
      final NoticiaModel noticia = NoticiaModel.fromJson(<String, dynamic>{
        'id': 4,
        'userId': 1,
        'title': 'T',
        'body': '',
      });

      expect(noticia.resumo, '');
    });

    test('trata campos ausentes de forma defensiva', () {
      final NoticiaModel noticia = NoticiaModel.fromJson(<String, dynamic>{
        'id': 9,
      });

      expect(noticia.id, 9);
      expect(noticia.titulo, '');
      expect(noticia.resumo, '');
      expect(noticia.conteudoCompleto, '');
      expect(noticia.autor, 'Autor ID 0');
      expect(noticia.urlImagem, 'https://picsum.photos/seed/post_9/1200/600');
      expect(noticia.dataPublicacao, isNull);
    });

    test('trata id inválido como 0 sem lançar exceção', () {
      final NoticiaModel noticia = NoticiaModel.fromJson(<String, dynamic>{
        'id': 'abc',
        'userId': 'xyz',
        'title': 123,
        'body': 456,
      });

      expect(noticia.id, 0);
      expect(noticia.autor, 'Autor ID 0');
      expect(noticia.titulo, '');
      expect(noticia.conteudoCompleto, '');
    });

    test('converte id numérico em string', () {
      final NoticiaModel noticia = NoticiaModel.fromJson(<String, dynamic>{
        'id': '42',
        'userId': '8',
        'title': 'T',
        'body': 'B',
      });

      expect(noticia.id, 42);
      expect(noticia.autor, 'Autor ID 8');
    });

    test('não inventa data: dataPublicacao fica nula sem o campo', () {
      final NoticiaModel noticia = NoticiaModel.fromJson(<String, dynamic>{
        'id': 1,
        'userId': 1,
        'title': 'T',
        'body': 'B',
      });

      expect(noticia.dataPublicacao, isNull);
    });

    test('usa a data quando a API a disponibiliza', () {
      final NoticiaModel noticia = NoticiaModel.fromJson(<String, dynamic>{
        'id': 1,
        'userId': 1,
        'title': 'T',
        'body': 'B',
        'dataPublicacao': '2024-05-01',
      });

      expect(noticia.dataPublicacao, '2024-05-01');
    });

    test('urlImagemPadrao é determinística por id', () {
      expect(
        NoticiaModel.urlImagemPadrao(10),
        'https://picsum.photos/seed/post_10/1200/600',
      );
    });
  });

  group('NoticiaModel.resumir', () {
    test('retorna o texto integral quando tem 40 caracteres ou menos', () {
      expect(NoticiaModel.resumir('abc'), 'abc');
      expect(NoticiaModel.resumir(''), '');
    });

    test('corta em 40 caracteres e adiciona reticências', () {
      final String resultado = NoticiaModel.resumir('x' * 60);
      expect(resultado, '${'x' * 40}...');
      expect(resultado.length, 43);
    });
  });

  group('NoticiaModel.toJson', () {
    test('preserva os principais campos', () {
      final NoticiaModel noticia = NoticiaModel.fromJson(<String, dynamic>{
        'id': 5,
        'userId': 2,
        'title': 'Título',
        'body': 'Conteúdo',
      });

      final Map<String, dynamic> json = noticia.toJson();
      expect(json['id'], 5);
      expect(json['title'], 'Título');
      expect(json['body'], 'Conteúdo');
      expect(json['urlImagem'], 'https://picsum.photos/seed/post_5/1200/600');
    });
  });
}
