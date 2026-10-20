/// Modelagem de dados para a entidade Notícia.
/// Representa uma notícia consumida da API JSONPlaceholder (posts).
class NoticiaModel {
  /// Identificador único da notícia.
  final int id;

  /// Identificador do autor (userId no JSON original).
  final int autorId;

  /// Título da notícia.
  final String titulo;

  /// Resumo breve (primeiras linhas do body).
  final String resumo;

  /// Conteúdo completo da notícia (body integral).
  final String conteudoCompleto;

  const NoticiaModel({
    required this.id,
    required this.autorId,
    required this.titulo,
    required this.resumo,
    required this.conteudoCompleto,
  });

  /// Factory que realiza o mapeamento JSON -> Dart.
  ///
  /// Mapeamento esperado:
  /// - `id` -> `id`
  /// - `userId` -> `autorId`
  /// - `title` -> `titulo`
  /// - `body` -> `resumo` e `conteudoCompleto`
  ///
  /// Tratamento defensivo:
  /// - Valida presença e tipo dos campos obrigatórios.
  /// - Não permite que objeto inválido seja transformado em registro válido.
  /// - Campos opcionais ausentes recebem valores padrão seguros.
  factory NoticiaModel.fromJson(Map<String, dynamic> json) {
    // Validação de campos obrigatórios
    if (!json.containsKey('id')) {
      throw const FormatException('Campo obrigatório ausente: id');
    }
    if (!json.containsKey('title')) {
      throw const FormatException('Campo obrigatório ausente: title');
    }
    if (!json.containsKey('body')) {
      throw const FormatException('Campo obrigatório ausente: body');
    }

    final dynamic rawId = json['id'];
    final dynamic rawTitle = json['title'];
    final dynamic rawBody = json['body'];
    final dynamic rawUserId = json['userId'];

    // Validação de tipos
    if (rawId is! int) {
      // Tenta conversão se vier como String numérica, caso contrário falha
      if (rawId is String) {
        final parsed = int.tryParse(rawId);
        if (parsed == null) {
          throw FormatException('Campo id com tipo inválido: $rawId');
        }
      } else {
        throw FormatException('Campo id com tipo inválido: $rawId');
      }
    }
    if (rawTitle is! String) {
      throw FormatException('Campo title com tipo inválido: $rawTitle');
    }
    if (rawBody is! String) {
      throw FormatException('Campo body com tipo inválido: $rawBody');
    }

    final int id = rawId is int ? rawId : int.parse(rawId as String);
    final String titulo = (rawTitle as String).trim();
    final String body = (rawBody as String).trim();

    if (titulo.isEmpty) {
      throw const FormatException('Campo title vazio é inválido');
    }
    if (body.isEmpty) {
      throw const FormatException('Campo body vazio é inválido');
    }

    // autorId é opcionalmente presente; se ausente, usa 0 como fallback seguro
    int autorId = 0;
    if (rawUserId != null) {
      if (rawUserId is int) {
        autorId = rawUserId;
      } else if (rawUserId is String) {
        autorId = int.tryParse(rawUserId) ?? 0;
      }
    }

    return NoticiaModel(
      id: id,
      autorId: autorId,
      titulo: titulo,
      resumo: body,
      conteudoCompleto: body,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': autorId,
      'title': titulo,
      'body': conteudoCompleto,
    };
  }

  @override
  String toString() {
    return 'NoticiaModel(id: $id, autorId: $autorId, titulo: $titulo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NoticiaModel &&
        other.id == id &&
        other.autorId == autorId &&
        other.titulo == titulo &&
        other.resumo == resumo &&
        other.conteudoCompleto == conteudoCompleto;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      autorId.hashCode ^
      titulo.hashCode ^
      resumo.hashCode ^
      conteudoCompleto.hashCode;
}
