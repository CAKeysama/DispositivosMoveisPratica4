import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/noticia_model.dart';

/// Serviço responsável por consumir a API de notícias.
///
/// Endpoint de demonstração compatível com os campos esperados:
/// https://jsonplaceholder.typicode.com/posts
///
/// O roteiro utiliza `api_noticias_endpoint` como placeholder.
/// Para entregar um aplicativo executável, centralizamos a URL em
/// [baseUrl] e documentamos a escolha no README.
class NoticiaService {
  /// URL base da API. Centralizada para facilitar alterações futuras.
  static const String baseUrl =
      'https://jsonplaceholder.typicode.com/posts';

  /// URL inválida usada quando a simulação de erro está ativa.
  static const String urlInvalidaParaSimulacao =
      'https://invalid.jsonplaceholder.typicode.com/posts_error';

  /// Timeout padrão para requisições HTTP.
  static const Duration timeoutPadrao = Duration(seconds: 10);

  /// Cliente HTTP injetável para facilitar testes com MockClient.
  final http.Client client;

  NoticiaService({http.Client? client}) : client = client ?? http.Client();

  /// Busca a lista de notícias da API.
  ///
  /// Fluxo:
  /// 1. Faz GET no endpoint configurado.
  /// 2. Verifica explicitamente se response.statusCode == 200.
  /// 3. Interpreta corpo com jsonDecode.
  /// 4. Verifica estrutura de lista JSON.
  /// 5. Converte cada elemento usando NoticiaModel.fromJson.
  /// 6. Retorna List<NoticiaModel>.
  /// 7. Lança exceção apropriada em falhas HTTP.
  /// 8. Trata erros de rede, timeout, conteúdo inválido sem ocultar causa real.
  Future<List<NoticiaModel>> buscarNoticias({
    bool simularErro = false,
    Duration timeout = timeoutPadrao,
    http.Client? overrideClient,
  }) async {
    final http.Client httpClient = overrideClient ?? client;
    final String url = simularErro ? urlInvalidaParaSimulacao : baseUrl;

    try {
      final http.Response response = await httpClient
          .get(Uri.parse(url))
          .timeout(timeout);

      // Verificação explícita do statusCode
      if (response.statusCode != 200) {
        throw HttpException(
          'Falha ao carregar notícias. Status: ${response.statusCode}',
          uri: Uri.parse(url),
        );
      }

      // Interpretação do corpo
      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException catch (e) {
        throw FormatException('Resposta JSON inválida: ${e.message}');
      }

      // Verificação de estrutura de lista
      if (decoded is! List) {
        throw const FormatException(
            'Formato inesperado: esperado uma lista JSON');
      }

      if (decoded.isEmpty) {
        return <NoticiaModel>[];
      }

      // Conversão de cada elemento
      final List<NoticiaModel> noticias = [];
      for (int i = 0; i < decoded.length; i++) {
        final dynamic item = decoded[i];
        if (item is! Map<String, dynamic>) {
          // Tenta converter se for Map<dynamic,dynamic>
          if (item is Map) {
            try {
              final Map<String, dynamic> converted =
                  Map<String, dynamic>.from(item);
              noticias.add(NoticiaModel.fromJson(converted));
            } catch (e) {
              throw FormatException(
                  'Item $i com formato inválido: $e. Dados: $item');
            }
          } else {
            throw FormatException('Item $i não é um objeto JSON: $item');
          }
        } else {
          try {
            noticias.add(NoticiaModel.fromJson(item));
          } catch (e) {
            // Re-lança com contexto do índice para diagnóstico
            throw FormatException('Erro ao converter item $i: $e');
          }
        }
      }

      return noticias;
    } on TimeoutException {
      throw TimeoutException(
          'Tempo limite excedido ao tentar conectar à API ($url). Verifique sua conexão.');
    } on SocketException catch (e) {
      throw SocketException(
          'Erro de conexão: não foi possível alcançar $url. Detalhes: ${e.message}');
    } on HttpException {
      rethrow;
    } on FormatException {
      rethrow;
    } catch (e) {
      // Preserva causa real para diagnóstico
      throw Exception('Erro inesperado ao buscar notícias: $e');
    }
  }

  /// Fecha o cliente HTTP quando não for mais necessário.
  void dispose() {
    client.close();
  }
}
