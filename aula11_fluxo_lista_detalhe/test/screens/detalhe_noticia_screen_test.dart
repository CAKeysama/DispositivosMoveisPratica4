import 'dart:async';

import 'package:aula11_fluxo_lista_detalhe/models/noticia_model.dart';
import 'package:aula11_fluxo_lista_detalhe/screens/detalhe_noticia_screen.dart';
import 'package:aula11_fluxo_lista_detalhe/services/comentario_service.dart';
import 'package:aula11_fluxo_lista_detalhe/widgets/capa_noticia.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/api_fake.dart';

final NoticiaModel noticiaDeTeste = NoticiaModel.fromJson(<String, dynamic>{
  'id': 1,
  'userId': 4,
  'title': 'Notícia de teste completa',
  'body': 'Conteúdo integral da notícia de teste para verificação da tela.',
});

/// Monta o app com a tela de detalhes como home.
Widget montarApp({
  NoticiaModel? noticia,
  bool favorita = false,
  ComentarioService? comentarios,
}) {
  return MaterialApp(
    home: DetalheNoticiaScreen(
      noticia: noticia ?? noticiaDeTeste,
      inicialmenteFavorita: favorita,
      comentarioService: comentarios,
    ),
  );
}

void main() {
  group('DetalheNoticiaScreen - conteúdo', () {
    testWidgets('exibe AppBar, título, autor, data e conteúdo completo',
        (tester) async {
      await tester.pumpWidget(montarApp(
        comentarios: ComentarioService(
          client: ApiFake.resposta(statusCode: 200, body: '[]'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Detalhes da Notícia'), findsOneWidget);
      expect(find.text('Notícia de teste completa'), findsOneWidget);
      expect(find.text('Autor ID 4'), findsOneWidget);
      expect(find.text('Data não informada'), findsOneWidget);
      expect(
        find.text(
            'Conteúdo integral da notícia de teste para verificação da tela.'),
        findsOneWidget,
      );
    });

    testWidgets('exibe a data quando disponibilizada pelos dados',
        (tester) async {
      final NoticiaModel comData = NoticiaModel.fromJson(<String, dynamic>{
        'id': 2,
        'userId': 1,
        'title': 'Com data',
        'body': 'b',
        'dataPublicacao': '2024-05-01',
      });

      await tester.pumpWidget(montarApp(
        noticia: comData,
        comentarios: ComentarioService(
          client: ApiFake.resposta(statusCode: 200, body: '[]'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('2024-05-01'), findsOneWidget);
      expect(find.text('Data não informada'), findsNothing);
    });

    testWidgets('usa SingleChildScrollView + Column com rolagem', (tester) async {
      await tester.pumpWidget(montarApp(
        comentarios: ComentarioService(
          client: ApiFake.resposta(statusCode: 200, body: '[]'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('capa usa Hero com a tag da notícia', (tester) async {
      await tester.pumpWidget(montarApp(
        comentarios: ComentarioService(
          client: ApiFake.resposta(statusCode: 200, body: '[]'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate((Widget w) => w is Hero && w.tag == noticiaDeTeste.id),
        findsOneWidget,
      );
    });

    testWidgets('imagem de rede falha e mostra o placeholder local',
        (tester) async {
      await tester.pumpWidget(montarApp(
        comentarios: ComentarioService(
          client: ApiFake.resposta(statusCode: 200, body: '[]'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CapaNoticia), findsOneWidget);
      expect(find.textContaining('Imagem indisponível'), findsOneWidget);

      // A falha da imagem não impede a leitura da notícia.
      expect(find.text('Notícia de teste completa'), findsOneWidget);
    });
  });

  group('DetalheNoticiaScreen - favoritos', () {
    testWidgets('botão de favoritar inicia desmarcado e alterna o estado',
        (tester) async {
      await tester.pumpWidget(montarApp(
        comentarios: ComentarioService(
          client: ApiFake.resposta(statusCode: 200, body: '[]'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
      expect(find.text('Favorita'), findsOneWidget);
    });

    testWidgets('inicialmenteFavorita reflete o estado recebido do feed',
        (tester) async {
      await tester.pumpWidget(montarApp(
        favorita: true,
        comentarios: ComentarioService(
          client: ApiFake.resposta(statusCode: 200, body: '[]'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.text('Desfavoritar notícia'), findsOneWidget);
    });

    testWidgets('voltar retorna Navigator.pop(true) quando favoritada',
        (tester) async {
      bool? resultado;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  resultado = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute<bool>(
                      builder: (BuildContext context) => DetalheNoticiaScreen(
                        noticia: noticiaDeTeste,
                        comentarioService: ComentarioService(
                          client:
                              ApiFake.resposta(statusCode: 200, body: '[]'),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      expect(resultado, isTrue);
    });

    testWidgets('voltar retorna Navigator.pop(false) quando desfavoritada',
        (tester) async {
      bool? resultado;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  resultado = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute<bool>(
                      builder: (BuildContext context) => DetalheNoticiaScreen(
                        noticia: noticiaDeTeste,
                        inicialmenteFavorita: true,
                        comentarioService: ComentarioService(
                          client:
                              ApiFake.resposta(statusCode: 200, body: '[]'),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Desfavoritar notícia'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      expect(resultado, isFalse);
    });
  });

  group('DetalheNoticiaScreen - comentários', () {
    testWidgets('exibe estado de carregamento dos comentários', (tester) async {
      await tester.pumpWidget(montarApp(
        comentarios: ComentarioService(
          client: ApiFake.respostaLenta(
            atraso: const Duration(milliseconds: 400),
            body: '[]',
          ),
        ),
      ));

      // Um CircularProgressIndicator na seção de comentários.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // A notícia permanece visível durante o carregamento.
      expect(find.text('Comentários'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('lista de comentários mostra nome, e-mail e texto',
        (tester) async {
      await tester.pumpWidget(montarApp(
        comentarios: ComentarioService(
          client: ApiFake.comentariosComSucesso(quantidade: 2),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Comentarista 1'), findsOneWidget);
      expect(find.text('comentarista1@example.com'), findsOneWidget);
      expect(find.text('Comentário número 1 sobre a notícia.'), findsOneWidget);
      expect(find.text('Comentarista 2'), findsOneWidget);
      expect(find.text('comentarista2@example.com'), findsOneWidget);
      expect(find.text('Comentário número 2 sobre a notícia.'), findsOneWidget);
    });

    testWidgets('estado de lista vazia', (tester) async {
      await tester.pumpWidget(montarApp(
        comentarios: ComentarioService(
          client: ApiFake.resposta(statusCode: 200, body: '[]'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Nenhum comentário para esta notícia.'), findsOneWidget);
    });

    testWidgets('erro nos comentários preserva a notícia na tela',
        (tester) async {
      await tester.pumpWidget(montarApp(
        comentarios: ComentarioService(
          client: ApiFake.resposta(statusCode: 500, body: 'x'),
        ),
      ));
      await tester.pumpAndSettle();

      // Erro somente na região de comentários.
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);

      // A notícia continua disponível (título, autor e conteúdo).
      expect(find.text('Notícia de teste completa'), findsOneWidget);
      expect(find.text('Autor ID 4'), findsOneWidget);
      expect(
        find.text(
            'Conteúdo integral da notícia de teste para verificação da tela.'),
        findsOneWidget,
      );
    });

    testWidgets('falha de rede nos comentários mostra mensagem amigável',
        (tester) async {
      await tester.pumpWidget(montarApp(
        comentarios: ComentarioService(client: ApiFake.falhaDeRede()),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Verifique sua conexão'), findsOneWidget);
    });

    testWidgets('botão tentar novamente recarrega os comentários',
        (tester) async {
      bool falhar = true;
      await tester.pumpWidget(montarApp(
        comentarios: ComentarioService(
          client: MockClient((http.Request _) async {
            if (falhar) {
              return http.Response('erro', 503);
            }
            return http.Response(
              '[{"id":1,"postId":1,"name":"Recuperado","email":"r@example.com","body":"Comentário recuperado."}]',
              200,
            );
          }),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      falhar = false;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.text('Recuperado'), findsOneWidget);
      expect(find.text('Comentário recuperado.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('requisição de comentários usa o id da notícia recebida',
        (tester) async {
      final List<Uri> chamadas = <Uri>[];
      await tester.pumpWidget(montarApp(
        comentarios: ComentarioService(
          client: MockClient((http.Request request) async {
            chamadas.add(request.url);
            return http.Response('[]', 200);
          }),
        ),
      ));
      await tester.pumpAndSettle();

      expect(chamadas, hasLength(1));
      expect(chamadas.single.path, '/posts/${noticiaDeTeste.id}/comments');
    });

    testWidgets('reutiliza o objeto recebido sem refazer a requisição da notícia',
        (tester) async {
      // Somente a requisição de comentários é feita na tela de detalhes:
      // nenhum GET para /posts (lista ou item) acontece aqui.
      final List<String> caminhos = <String>[];
      await tester.pumpWidget(montarApp(
        comentarios: ComentarioService(
          client: MockClient((http.Request request) async {
            caminhos.add(request.url.path);
            return http.Response('[]', 200);
          }),
        ),
      ));
      await tester.pumpAndSettle();

      expect(caminhos, <String>['/posts/${noticiaDeTeste.id}/comments']);
    });
  });

  group('Timeout', () {
    testWidgets('comentários lentos não deixam a tela presa para sempre',
        (tester) async {
      final ComentarioService service = ComentarioService(
        client: MockClient((http.Request _) {
          return Completer<http.Response>().future; // nunca responde
        }),
        timeout: const Duration(milliseconds: 100),
      );

      await tester.pumpWidget(montarApp(comentarios: service));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Com o timeout, o estado de erro aparece em vez de carregamento eterno.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });
  });
}
