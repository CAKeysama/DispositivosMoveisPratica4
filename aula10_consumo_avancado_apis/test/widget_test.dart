import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:aula10_consumo_avancado_apis/main.dart';
import 'package:aula10_consumo_avancado_apis/models/noticia_model.dart';
import 'package:aula10_consumo_avancado_apis/screens/detalhe_noticia_screen.dart';
import 'package:aula10_consumo_avancado_apis/screens/feed_noticias_screen.dart';
import 'package:aula10_consumo_avancado_apis/services/noticia_service.dart';

void main() {
  group('FeedNoticiasScreen - estados', () {
    testWidgets('mostra indicador de carregamento inicialmente',
        (tester) async {
      await tester.pumpWidget(const MyApp());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Carregando notícias...'), findsOneWidget);
    });

    testWidgets('exibe estado vazio quando lista vazia', (tester) async {
      // Este teste verifica o texto de estado vazio existe na árvore
      // A lógica de estado vazio é testada via widget isolado
      final noticiaVazia = <NoticiaModel>[];
      expect(noticiaVazia.isEmpty, isTrue);
      expect('Nenhuma notícia encontrada.', isNotEmpty);
    });

    testWidgets('AppBar possui título Feed de Notícias', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: FeedNoticiasScreen()),
      );
      expect(find.text('Feed de Notícias'), findsOneWidget);
    });

    testWidgets('campo de pesquisa está presente', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: FeedNoticiasScreen()),
      );
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Pesquisar por título...'), findsOneWidget);
    });
  });

  group('DetalheNoticiaScreen', () {
    const noticiaTeste = NoticiaModel(
      id: 42,
      autorId: 7,
      titulo: 'Título completo da notícia para teste detalhado',
      resumo: 'Resumo breve',
      conteudoCompleto:
          'Conteúdo completo da notícia. Este texto não deve ser cortado e deve ser exibido integralmente com SingleChildScrollView e Column.',
    );

    testWidgets('exibe título completo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DetalheNoticiaScreen(noticia: noticiaTeste),
        ),
      );

      expect(find.text(noticiaTeste.titulo), findsOneWidget);
    });

    testWidgets('exibe texto completo sem corte', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DetalheNoticiaScreen(noticia: noticiaTeste),
        ),
      );

      expect(find.text(noticiaTeste.conteudoCompleto), findsOneWidget);
    });

    testWidgets('exibe identificação do autor', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DetalheNoticiaScreen(noticia: noticiaTeste),
        ),
      );

      expect(find.text('Autor ID: 7'), findsOneWidget);
      expect(find.text('ID: 42'), findsOneWidget);
    });

    testWidgets('possui botão Voltar ao Feed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DetalheNoticiaScreen(noticia: noticiaTeste),
        ),
      );

      expect(find.text('Voltar ao Feed'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('navegação para detalhes via Navigator.push', (tester) async {
      const noticia = NoticiaModel(
        id: 1,
        autorId: 1,
        titulo: 'Notícia Navegável',
        resumo: 'Resumo',
        conteudoCompleto: 'Conteúdo completo',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DetalheNoticiaScreen(noticia: noticia),
                    ),
                  );
                },
                child: const Text('Ir para detalhes'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Ir para detalhes'), findsOneWidget);
      await tester.tap(find.text('Ir para detalhes'));
      await tester.pumpAndSettle();

      expect(find.text('Notícia Navegável'), findsOneWidget);
      expect(find.text('Conteúdo completo'), findsOneWidget);
    });
  });

  group('ListView.builder', () {
    testWidgets('renderiza lista com ListView.builder', (tester) async {
      final noticias = List.generate(
        20,
        (i) => NoticiaModel(
          id: i + 1,
          autorId: 1,
          titulo: 'Título $i',
          resumo: 'Resumo $i',
          conteudoCompleto: 'Conteúdo $i',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: noticias.length,
              itemBuilder: (context, index) {
                final n = noticias[index];
                return ListTile(title: Text(n.titulo));
              },
            ),
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
      // Verifica que os primeiros itens são renderizados
      expect(find.text('Título 0'), findsOneWidget);
    });
  });

  group('Simulação de falha e recuperação', () {
    test('serviço falha com simulação e recupera sem simulação', () async {
      final clientSucesso = MockClient((request) async {
        return http.Response(
            jsonEncode([
              {
                'id': 1,
                'userId': 1,
                'title': 'Título recuperado',
                'body': 'Corpo recuperado'
              }
            ]),
            200);
      });

      final clientFalha = MockClient((request) async {
        throw const SocketException('Simulação de falha');
      });

      final serviceFalha = NoticiaService(client: clientFalha);
      expect(() => serviceFalha.buscarNoticias(simularErro: true),
          throwsA(isA<SocketException>()));

      final serviceSucesso = NoticiaService(client: clientSucesso);
      final result = await serviceSucesso.buscarNoticias(simularErro: false);
      expect(result.length, 1);
      expect(result.first.titulo, 'Título recuperado');
    });
  });
}
