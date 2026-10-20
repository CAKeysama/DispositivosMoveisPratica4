import 'package:flutter_test/flutter_test.dart';
import 'package:aula10_consumo_avancado_apis/models/noticia_model.dart';

void main() {
  group('NoticiaModel.fromJson', () {
    test('mapeia corretamente todos os campos JSON', () {
      final json = {
        'id': 1,
        'userId': 10,
        'title': 'Título de teste',
        'body': 'Corpo da notícia de teste',
      };

      final noticia = NoticiaModel.fromJson(json);

      expect(noticia.id, 1);
      expect(noticia.autorId, 10);
      expect(noticia.titulo, 'Título de teste');
      expect(noticia.resumo, 'Corpo da notícia de teste');
      expect(noticia.conteudoCompleto, 'Corpo da notícia de teste');
    });

    test('trata autorId ausente com valor padrão 0', () {
      final json = {
        'id': 2,
        'title': 'Sem autor',
        'body': 'Corpo sem autor',
      };

      final noticia = NoticiaModel.fromJson(json);

      expect(noticia.autorId, 0);
      expect(noticia.id, 2);
    });

    test('lança FormatException quando id ausente', () {
      final json = {
        'userId': 1,
        'title': 'Título',
        'body': 'Corpo',
      };

      expect(() => NoticiaModel.fromJson(json),
          throwsA(isA<FormatException>()));
    });

    test('lança FormatException quando title ausente', () {
      final json = {
        'id': 1,
        'userId': 1,
        'body': 'Corpo',
      };

      expect(() => NoticiaModel.fromJson(json),
          throwsA(isA<FormatException>()));
    });

    test('lança FormatException quando body ausente', () {
      final json = {
        'id': 1,
        'userId': 1,
        'title': 'Título',
      };

      expect(() => NoticiaModel.fromJson(json),
          throwsA(isA<FormatException>()));
    });

    test('lança FormatException quando título vazio', () {
      final json = {
        'id': 1,
        'userId': 1,
        'title': '   ',
        'body': 'Corpo válido',
      };

      expect(() => NoticiaModel.fromJson(json),
          throwsA(isA<FormatException>()));
    });

    test('não transforma silenciosamente JSON inválido em registro válido',
        () {
      final jsonInvalido = {
        'id': 'não é int',
        'title': 12345,
        'body': null,
      };

      expect(() => NoticiaModel.fromJson(jsonInvalido),
          throwsA(isA<FormatException>()));
    });

    test('mapeamento body para resumo e conteudoCompleto iguais', () {
      final json = {
        'id': 5,
        'userId': 3,
        'title': 'Notícia 5',
        'body': 'Conteúdo completo da notícia 5',
      };

      final noticia = NoticiaModel.fromJson(json);

      expect(noticia.resumo, noticia.conteudoCompleto);
      expect(noticia.resumo, 'Conteúdo completo da notícia 5');
    });

    test('toJson converte corretamente', () {
      const noticia = NoticiaModel(
        id: 1,
        autorId: 2,
        titulo: 'Título',
        resumo: 'Resumo',
        conteudoCompleto: 'Conteúdo',
      );

      final json = noticia.toJson();

      expect(json['id'], 1);
      expect(json['userId'], 2);
      expect(json['title'], 'Título');
      expect(json['body'], 'Conteúdo');
    });

    test('converte lista JSON válida para objetos Dart', () {
      final listaJson = [
        {
          'id': 1,
          'userId': 1,
          'title': 'Título 1',
          'body': 'Corpo 1',
        },
        {
          'id': 2,
          'userId': 1,
          'title': 'Título 2',
          'body': 'Corpo 2',
        },
      ];

      final noticias =
          listaJson.map((e) => NoticiaModel.fromJson(e)).toList();

      expect(noticias.length, 2);
      expect(noticias[0].titulo, 'Título 1');
      expect(noticias[1].titulo, 'Título 2');
    });
  });

  group('Busca por título', () {
    test('filtra sem diferenciar maiúsculas e minúsculas', () {
      final noticias = [
        const NoticiaModel(
            id: 1,
            autorId: 1,
            titulo: 'Flutter Avançado',
            resumo: 'resumo',
            conteudoCompleto: 'conteudo'),
        const NoticiaModel(
            id: 2,
            autorId: 1,
            titulo: 'Dart Básico',
            resumo: 'resumo',
            conteudoCompleto: 'conteudo'),
        const NoticiaModel(
            id: 3,
            autorId: 1,
            titulo: 'Consumo de APIs',
            resumo: 'resumo',
            conteudoCompleto: 'conteudo'),
      ];

      String query = 'flutter';
      final filtradas = noticias
          .where((n) => n.titulo.toLowerCase().contains(query.toLowerCase()))
          .toList();

      expect(filtradas.length, 1);
      expect(filtradas.first.id, 1);
    });

    test('retorna lista vazia quando busca sem resultados', () {
      final noticias = [
        const NoticiaModel(
            id: 1,
            autorId: 1,
            titulo: 'Flutter',
            resumo: 'resumo',
            conteudoCompleto: 'conteudo'),
      ];

      const query = 'InexistenteXYZ';
      final filtradas = noticias
          .where((n) => n.titulo.toLowerCase().contains(query.toLowerCase()))
          .toList();

      expect(filtradas, isEmpty);
    });

    test('preserva lista original após filtro', () {
      final original = [
        const NoticiaModel(
            id: 1,
            autorId: 1,
            titulo: 'A',
            resumo: 'resumo',
            conteudoCompleto: 'conteudo'),
        const NoticiaModel(
            id: 2,
            autorId: 1,
            titulo: 'B',
            resumo: 'resumo',
            conteudoCompleto: 'conteudo'),
      ];

      final filtradas = original
          .where((n) => n.titulo.toLowerCase().contains('a'))
          .toList();

      expect(original.length, 2);
      expect(filtradas.length, 1);
    });
  });
}
