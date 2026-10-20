/// Modelo de dados de um comentário associado a uma notícia.
///
/// Preenchido a partir do JSON da API de demonstração
/// (JSONPlaceholder - endpoint `/posts/{id}/comments`) por meio de
/// [ComentarioModel.fromJson].
class ComentarioModel {
  /// Identificador único do comentário (campo `id` da API).
  final int id;

  /// Nome de quem comentou (campo `name` da API).
  final String nome;

  /// E-mail de quem comentou (campo `email` da API), quando disponível.
  final String email;

  /// Texto do comentário (campo `body` da API).
  final String texto;

  /// Id da notícia à qual o comentário pertence (campo `postId` da API).
  final int noticiaId;

  const ComentarioModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.texto,
    required this.noticiaId,
  });

  /// Constrói um [ComentarioModel] a partir do mapa JSON vindo da API.
  ///
  /// Campos ausentes ou inválidos são tratados de forma defensiva.
  factory ComentarioModel.fromJson(Map<String, dynamic> json) {
    final int id = _inteiroOuZero(json['id']);
    final int noticiaId = _inteiroOuZero(json['postId']);
    final String email = _textoOuVazio(json['email']).trim();

    return ComentarioModel(
      id: id,
      nome: _textoOuVazio(json['name']).trim(),
      email: email,
      texto: _textoOuVazio(json['body']).trim(),
      noticiaId: noticiaId,
    );
  }

  /// Converte o comentário para JSON (útil para persistência e testes).
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'postId': noticiaId,
      'name': nome,
      'email': email,
      'body': texto,
    };
  }

  static int _inteiroOuZero(dynamic valor) =>
      valor is int ? valor : int.tryParse('$valor') ?? 0;

  static String _textoOuVazio(dynamic valor) => valor is String ? valor : '';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComentarioModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nome == other.nome &&
          email == other.email &&
          texto == other.texto &&
          noticiaId == other.noticiaId;

  @override
  int get hashCode => Object.hash(id, nome, email, texto, noticiaId);

  @override
  String toString() =>
      'ComentarioModel(id: $id, nome: $nome, noticiaId: $noticiaId)';
}
