import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/noticia_model.dart';

/// Exceção base lançada pelo [NoticiaService].
///
/// As mensagens são amigáveis para o usuário final; detalhes técnicos
/// ficam apenas no [tecnico], para debug/testes.
class NoticiaServiceException implements Exception {
  final String mensagem;
  final Object? tecnico;

  const NoticiaServiceException(this.mensagem, {this.tecnico});

  @override
  String toString() => 'NoticiaServiceException: $mensagem';
}

/// Falha de comunicação com a rede (sem conexão, DNS, timeout etc.).
class NoticiaRedeException extends NoticiaServiceException {
  const NoticiaRedeException(super.mensagem, {super.tecnico});
}

/// A API respondeu com um status HTTP diferente de 200.
class NoticiaHttpException extends NoticiaServiceException {
  final int statusCode;

  const NoticiaHttpException(
    super.mensagem, {
    required this.statusCode,
    super.tecnico,
  });
}

/// A resposta recebida não tem o formato esperado (JSON/lista inválida).
class NoticiaFormatoException extends NoticiaServiceException {
  const NoticiaFormatoException(super.mensagem, {super.tecnico});
}

/// Serviço de consumo da API REST de notícias.
///
/// A lógica HTTP fica isolada da interface (nenhum código de rede dentro
/// de `build`). O [http.Client] é injetável para permitir testes
/// automatizados previsíveis, sem depender da API pública.
class NoticiaService {
  /// Endpoint público de demonstração (JSONPlaceholder).
  ///
  /// O roteiro usa `api.servidor/posts` como placeholder; para o app
  /// funcionar de verdade, esse placeholder foi substituído por um
  /// endpoint público compatível com os campos esperados.
  static const String endpointPadrao =
      'https://jsonplaceholder.typicode.com/posts';

  final http.Client _client;
  final Uri _endpoint;
  final Duration _timeout;

  NoticiaService({
    http.Client? client,
    String? endpoint,
    Duration timeout = const Duration(seconds: 15),
  })  : _client = client ?? http.Client(),
        _endpoint = Uri.parse(endpoint ?? endpointPadrao),
        _timeout = timeout;

  /// Busca a lista completa de notícias da API.
  ///
  /// 1. Faz uma requisição HTTP GET.
  /// 2. Verifica `response.statusCode == 200`.
  /// 3. Decodifica o JSON.
  /// 4. Valida que a resposta é uma lista.
  /// 5. Mapeia os elementos com [NoticiaModel.fromJson].
  ///
  /// Lança [NoticiaHttpException] para respostas HTTP malsucedidas,
  /// [NoticiaFormatoException] para JSON/lista inválidos e
  /// [NoticiaRedeException] para falhas de rede e timeout.
  Future<List<NoticiaModel>> buscarNoticias() async {
    final http.Response response;
    try {
      response = await _client.get(_endpoint).timeout(_timeout);
    } on Exception catch (erro) {
      throw NoticiaRedeException(
        'Não foi possível conectar ao servidor de notícias. '
        'Verifique sua conexão e tente novamente.',
        tecnico: erro,
      );
    }

    if (response.statusCode != 200) {
      throw NoticiaHttpException(
        'O servidor de notícias respondeu com um erro '
        '(código ${response.statusCode}). Tente novamente mais tarde.',
        statusCode: response.statusCode,
      );
    }

    final List<dynamic> lista;
    try {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const FormatException('A resposta não é uma lista.');
      }
      lista = decoded;
    } on Exception catch (erro) {
      throw NoticiaFormatoException(
        'O servidor de notícias retornou dados em formato inválido.',
        tecnico: erro,
      );
    }

    return lista
        .whereType<Map<String, dynamic>>()
        .map(NoticiaModel.fromJson)
        .toList(growable: false);
  }
}
