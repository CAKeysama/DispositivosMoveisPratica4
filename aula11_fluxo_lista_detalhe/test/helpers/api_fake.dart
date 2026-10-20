import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Utilitários de teste: clientes HTTP falsos para não depender da API pública.
///
/// Os cenários simulam exatamente as respostas que a aplicação recebe da
/// API real, mantendo os testes automatizados previsíveis.
class ApiFake {
  ApiFake._();

  /// Lista de notícias em JSON no formato da API de demonstração.
  static List<Map<String, dynamic>> noticiasJson({
    int quantidade = 2,
    int corpoLength = 120,
  }) {
    return List<Map<String, dynamic>>.generate(quantidade, (int i) {
      final int id = i + 1;
      return <String, dynamic>{
        'id': id,
        'userId': id + 10,
        'title': 'Título da notícia $id',
        'body': 'Corpo da notícia número $id. '.padRight(corpoLength, 'x'),
      };
    });
  }

  /// Lista de comentários em JSON no formato da API de demonstração.
  static List<Map<String, dynamic>> comentariosJson({int quantidade = 2}) {
    return List<Map<String, dynamic>>.generate(quantidade, (int i) {
      final int id = i + 1;
      return <String, dynamic>{
        'id': id,
        'postId': 1,
        'name': 'Comentarista $id',
        'email': 'comentarista$id@example.com',
        'body': 'Comentário número $id sobre a notícia.',
      };
    });
  }

  /// Cliente que responde com [body] e [statusCode] para qualquer GET.
  static MockClient resposta({
    required int statusCode,
    required String body,
  }) {
    return MockClient((http.Request request) async {
      return http.Response(body, statusCode);
    });
  }

  /// Cliente que responde com JSON de notícias com sucesso (200).
  static MockClient noticiasComSucesso({int quantidade = 2}) {
    return resposta(
      statusCode: 200,
      body: jsonEncode(noticiasJson(quantidade: quantidade)),
    );
  }

  /// Cliente que responde com JSON de comentários com sucesso (200).
  static MockClient comentariosComSucesso({int quantidade = 2}) {
    return resposta(
      statusCode: 200,
      body: jsonEncode(comentariosJson(quantidade: quantidade)),
    );
  }

  /// Cliente que simula falha de rede (exceção de cliente HTTP).
  static MockClient falhaDeRede() {
    return MockClient((http.Request request) async {
      throw http.ClientException('Sem conexão com a internet (teste).');
    });
  }

  /// Cliente que demora [atraso] para responder (para testar timeout).
  static MockClient respostaLenta({
    Duration atraso = const Duration(milliseconds: 300),
    String body = '[]',
  }) {
    return MockClient((http.Request request) async {
      await Future<void>.delayed(atraso);
      return http.Response(body, 200);
    });
  }
}
