import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/comentario_model.dart';
import 'noticia_service.dart'
    show
        NoticiaFormatoException,
        NoticiaHttpException,
        NoticiaRedeException;

/// Serviço de consumo da API REST de comentários.
///
/// A requisição de comentários é independente da requisição da notícia:
/// uma falha aqui não derruba a tela de detalhes, apenas a seção de
/// comentários. O [http.Client] é injetável para testes previsíveis.
class ComentarioService {
  /// Endpoint base de demonstração (JSONPlaceholder).
  static const String endpointBasePadrao =
      'https://jsonplaceholder.typicode.com';

  final http.Client _client;
  final Uri _endpointBase;
  final Duration _timeout;

  ComentarioService({
    http.Client? client,
    String? endpointBase,
    Duration timeout = const Duration(seconds: 15),
  })  : _client = client ?? http.Client(),
        _endpointBase = Uri.parse(endpointBase ?? endpointBasePadrao),
        _timeout = timeout;

  /// Busca os comentários da notícia [noticiaId].
  ///
  /// Endpoint compatível: `https://jsonplaceholder.typicode.com/posts/{id}/comments`.
  ///
  /// Lança [NoticiaHttpException] para respostas HTTP malsucedidas,
  /// [NoticiaFormatoException] para JSON/lista inválidos e
  /// [NoticiaRedeException] para falhas de rede e timeout.
  Future<List<ComentarioModel>> buscarComentarios(int noticiaId) async {
    final Uri endpoint =
        _endpointBase.replace(path: '/posts/$noticiaId/comments');

    final http.Response response;
    try {
      response = await _client.get(endpoint).timeout(_timeout);
    } on Exception catch (erro) {
      throw NoticiaRedeException(
        'Não foi possível carregar os comentários. '
        'Verifique sua conexão e tente novamente.',
        tecnico: erro,
      );
    }

    if (response.statusCode != 200) {
      throw NoticiaHttpException(
        'O servidor de comentários respondeu com um erro '
        '(código ${response.statusCode}).',
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
        'O servidor de comentários retornou dados em formato inválido.',
        tecnico: erro,
      );
    }

    return lista
        .whereType<Map<String, dynamic>>()
        .map(ComentarioModel.fromJson)
        .toList(growable: false);
  }
}
