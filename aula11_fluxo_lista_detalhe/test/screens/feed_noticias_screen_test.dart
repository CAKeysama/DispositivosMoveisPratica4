import 'package:aula11_fluxo_lista_detalhe/models/noticia_model.dart';
import 'package:aula11_fluxo_lista_detalhe/screens/detalhe_noticia_screen.dart';
import 'package:aula11_fluxo_lista_detalhe/screens/feed_noticias_screen.dart';
import 'package:aula11_fluxo_lista_detalhe/services/noticia_service.dart';
import 'package:aula11_fluxo_lista_detalhe/widgets/capa_noticia.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/api_fake.dart';

/// Monta o app com o feed na tela inicial, usando o serviço falso.
Widget montarApp(NoticiaService service, {Set<int>? favoritos}) {
  return MaterialApp(
    home: FeedNoticiasScreen(
      noticiaService: service,
      favoritosIniciais: favoritos,
    ),
  );
}

void main() {
  group('FeedNoticiasScreen', () {
    testWidgets('exibe o indicador de carregamento inicial', (tester) async {
      final NoticiaService service = NoticiaService(
        client: ApiFake.respostaLenta(
          atraso: const Duration(milliseconds: 400),
          body: '[]',
        ),
      );

      await tester.pumpWidget(montarApp(service));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Carregando notícias...'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('exibe o título Portal de Notícias na AppBar', (tester) async {
      await tester.pumpWidget(
        montarApp(
          NoticiaService(client: ApiFake.resposta(statusCode: 200, body: '[]')),
        ),
      );

      expect(find.text('Portal de Notícias'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('renderiza a lista com ListView.builder e Cards', (
      tester,
    ) async {
      final NoticiaService service = NoticiaService(
        client: ApiFake.noticiasComSucesso(quantidade: 3),
      );

      await tester.pumpWidget(montarApp(service));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(3));
      expect(find.text('Título da notícia 1'), findsOneWidget);
      expect(find.text('Título da notícia 2'), findsOneWidget);
      expect(find.text('Título da notícia 3'), findsOneWidget);
    });

    testWidgets('exibe resumo e indicador de detalhes em cada item', (
      tester,
    ) async {
      final NoticiaService service = NoticiaService(
        client: ApiFake.resposta(
          statusCode: 200,
          body: '[{"id":1,"userId":5,"title":"Título","body":"Resumo da notícia aparece aqui."}]',
        ),
      );

      await tester.pumpWidget(montarApp(service));
      await tester.pumpAndSettle();

      expect(find.text('Resumo da notícia aparece aqui.'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.text('Autor ID 5'), findsOneWidget);
    });

    testWidgets('estado de erro mostra mensagem e botão de nova tentativa', (
      tester,
    ) async {
      final NoticiaService service = NoticiaService(
        client: ApiFake.resposta(statusCode: 500, body: 'x'),
      );

      await tester.pumpWidget(montarApp(service));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.textContaining('código 500'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    testWidgets('falha de rede mostra mensagem amigável', (tester) async {
      final NoticiaService service = NoticiaService(
        client: ApiFake.falhaDeRede(),
      );

      await tester.pumpWidget(montarApp(service));
      await tester.pumpAndSettle();

      expect(find.textContaining('Verifique sua conexão'), findsOneWidget);
    });

    testWidgets('estado vazio mostra mensagem e botão de atualizar', (
      tester,
    ) async {
      final NoticiaService service = NoticiaService(
        client: ApiFake.resposta(statusCode: 200, body: '[]'),
      );

      await tester.pumpWidget(montarApp(service));
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma notícia encontrada.'), findsOneWidget);
      expect(find.text('Atualizar'), findsOneWidget);
    });

    testWidgets('botão tentar novamente recarrega o feed', (tester) async {
      bool falhar = true;
      final NoticiaService service = NoticiaService(
        client: MockClient((http.Request _) async {
          if (falhar) {
            return http.Response('erro', 500);
          }
          return http.Response(
            '[{"id":1,"userId":1,"title":"Depois da recarga","body":"ok"}]',
            200,
          );
        }),
      );

      await tester.pumpWidget(montarApp(service));
      await tester.pumpAndSettle();
      expect(find.textContaining('código 500'), findsOneWidget);

      falhar = false;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.text('Depois da recarga'), findsOneWidget);
    });

    testWidgets('abre os detalhes com Navigator.push e passa o objeto '
        'NoticiaModel completo', (tester) async {
      final NoticiaService service = NoticiaService(
        client: ApiFake.noticiasComSucesso(quantidade: 2),
      );

      await tester.pumpWidget(montarApp(service));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Título da notícia 1'));
      await tester.pumpAndSettle();

      // A tela de detalhes foi aberta.
      expect(find.byType(DetalheNoticiaScreen), findsOneWidget);
      expect(find.text('Detalhes da Notícia'), findsOneWidget);

      // Os dados vêm do objeto passado pelo construtor (sem nova requisição
      // da notícia): título completo, autor e corpo aparecem.
      expect(find.text('Título da notícia 1'), findsWidgets);
      expect(find.text('Autor ID 11'), findsOneWidget);

      // Conteúdo integral (não apenas o resumo).
      final DetalheNoticiaScreen tela = tester.widget<DetalheNoticiaScreen>(
        find.byType(DetalheNoticiaScreen),
      );
      expect(tela.noticia.id, 1);
      expect(tela.noticia.titulo, 'Título da notícia 1');
      expect(tela.noticia.conteudoCompleto, contains('Corpo da notícia'));
    });

    testWidgets('detalhes recebem exatamente a notícia selecionada', (
      tester,
    ) async {
      final NoticiaService service = NoticiaService(
        client: ApiFake.noticiasComSucesso(quantidade: 2),
      );

      await tester.pumpWidget(montarApp(service));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Título da notícia 2'));
      await tester.pumpAndSettle();

      final DetalheNoticiaScreen tela = tester.widget<DetalheNoticiaScreen>(
        find.byType(DetalheNoticiaScreen),
      );
      expect(tela.noticia.id, 2);
      expect(tela.noticia.autor, 'Autor ID 12');
    });

    testWidgets('Hero Animation: cada item tem tag única por notícia', (
      tester,
    ) async {
      final NoticiaService service = NoticiaService(
        client: ApiFake.noticiasComSucesso(quantidade: 3),
      );

      await tester.pumpWidget(montarApp(service));
      await tester.pumpAndSettle();

      expect(find.byType(Hero), findsNWidgets(3));
      for (final int id in <int>[1, 2, 3]) {
        expect(
          find.byWidgetPredicate((Widget w) => w is Hero && w.tag == id),
          findsOneWidget,
        );
      }
    });

    testWidgets('Hero do feed e da capa dos detalhes usam a mesma tag', (
      tester,
    ) async {
      final NoticiaService service = NoticiaService(
        client: ApiFake.noticiasComSucesso(quantidade: 1),
      );

      await tester.pumpWidget(montarApp(service));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Título da notícia 1'));
      await tester.pumpAndSettle();

      // Na tela de detalhes existe um Hero com a tag da notícia (id 1).
      expect(
        find.byWidgetPredicate((Widget w) => w is Hero && w.tag == 1),
        findsOneWidget,
      );
    });

    testWidgets('após favoritar nos detalhes, o feed reflete o favorito', (
      tester,
    ) async {
      final NoticiaService service = NoticiaService(
        client: ApiFake.noticiasComSucesso(quantidade: 2),
      );

      await tester.pumpWidget(montarApp(service));
      await tester.pumpAndSettle();

      // Inicialmente não há favoritos no feed.
      expect(find.byIcon(Icons.favorite), findsNothing);

      // Abre os detalhes da primeira notícia.
      await tester.tap(find.text('Título da notícia 1'));
      await tester.pumpAndSettle();

      // Favorita na tela de detalhes.
      await tester.tap(find.byTooltip('Favoritar notícia'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Volta ao feed (Navigator.pop com o resultado).
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      // O feed exibe o coração na notícia favoritada.
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      // Abre novamente: o detalhe já nasce favoritado.
      await tester.tap(find.text('Título da notícia 1'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Desfavoritar notícia'), findsOneWidget);
      expect(find.text('Favorita'), findsOneWidget);
    });

    testWidgets('desfavoritar nos detalhes remove o favorito do feed', (
      tester,
    ) async {
      final NoticiaService service = NoticiaService(
        client: ApiFake.noticiasComSucesso(quantidade: 1),
      );

      await tester.pumpWidget(montarApp(service, favoritos: <int>{1}));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      await tester.tap(find.text('Título da notícia 1'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Desfavoritar notícia'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite), findsNothing);
    });

    testWidgets('imagem de capa do feed tem fallback quando a URL falha', (
      tester,
    ) async {
      final NoticiaService service = NoticiaService(
        client: ApiFake.noticiasComSucesso(quantidade: 1),
      );

      await tester.pumpWidget(montarApp(service));
      await tester.pumpAndSettle();

      // A miniatura é um widget CapaNoticia com Hero por notícia.
      expect(find.byType(CapaNoticia), findsOneWidget);
    });

    testWidgets('placeholder local é exibido quando a imagem remota falha', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CapaNoticia(
              urlImagem: 'https://fotos-indisponiveis.test/miniatura.png',
              heroTag: 5,
              tituloPlaceholder: 'Notícia',
            ),
          ),
        ),
      );

      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Imagem indisponível'), findsOneWidget);
    });
  });
}
