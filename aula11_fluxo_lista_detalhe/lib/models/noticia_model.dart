/// Modelo de dados de uma notícia exibida no portal.
///
/// Os campos são preenchidos a partir do JSON da API de demonstração
/// (JSONPlaceholder - endpoint `/posts`) por meio de
/// [NoticiaModel.fromJson].
class NoticiaModel {
  /// Identificador único da notícia (campo `id` da API).
  final int id;

  /// Título completo da notícia (campo `title` da API).
  final String titulo;

  /// Resumo da notícia: os primeiros 40 caracteres do corpo do texto.
  final String resumo;

  /// Conteúdo integral da notícia (campo `body` da API).
  final String conteudoCompleto;

  /// Autor da notícia, exibido como `Autor ID N` (derivado de `userId`).
  final String autor;

  /// URL da imagem de capa da notícia.
  ///
  /// A API de demonstração não fornece imagem de capa, então a URL é
  /// configurada de forma determinística a partir do id da notícia
  /// (ver [NoticiaModel.urlImagemPadrao]).
  final String urlImagem;

  /// Data de publicação, quando disponibilizada pela API.
  ///
  /// A API de demonstração não fornece esse campo; quando ausente o valor
  /// fica `null` e a interface exibe `Data não informada`. Nenhuma data é
  /// inventada pelo aplicativo.
  final String? dataPublicacao;

  const NoticiaModel({
    required this.id,
    required this.titulo,
    required this.resumo,
    required this.conteudoCompleto,
    required this.autor,
    required this.urlImagem,
    this.dataPublicacao,
  });

  /// Comprimento máximo do [resumo] extraído do corpo do texto.
  static const int tamanhoMaximoResumo = 40;

  /// Gera a URL determinística da imagem de capa de uma notícia.
  ///
  /// Exemplo: `https://picsum.photos/seed/post_7/1200/600`.
  static String urlImagemPadrao(int id) =>
      'https://picsum.photos/seed/post_$id/1200/600';

  /// Constrói uma [NoticiaModel] a partir do mapa JSON vindo da API.
  ///
  /// Mapeamento:
  /// * `id` → [id]
  /// * `title` → [titulo]
  /// * `body` (primeiros 40 caracteres) → [resumo]
  /// * `body` (completo) → [conteudoCompleto]
  /// * `userId` (apresentado como `Autor ID N`) → [autor]
  /// * URL determinística pelo id → [urlImagem]
  /// * `dataPublicacao` (opcional) → [dataPublicacao]
  ///
  /// Campos ausentes ou inválidos são tratados de forma defensiva, sem
  /// lançar exceções durante a conversão.
  factory NoticiaModel.fromJson(Map<String, dynamic> json) {
    final dynamic idBruto = json['id'];
    final int id = idBruto is int
        ? idBruto
        : int.tryParse('$idBruto') ?? 0;

    final String conteudo = _textoOuVazio(json['body']);
    final String titulo = _textoOuVazio(json['title']);
    final String autor = _autorAPartirDe(json['userId']);
    final String? data = _dataOpcional(json['dataPublicacao']);

    return NoticiaModel(
      id: id,
      titulo: titulo,
      resumo: resumir(conteudo),
      conteudoCompleto: conteudo,
      autor: autor,
      urlImagem: urlImagemPadrao(id),
      dataPublicacao: data,
    );
  }

  /// Converte a notícia para JSON (útil para persistência e testes).
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': titulo,
      'body': conteudoCompleto,
      'autor': autor,
      'urlImagem': urlImagem,
      'dataPublicacao': dataPublicacao,
    };
  }

  /// Gera o [resumo] com no máximo [tamanhoMaximoResumo] caracteres.
  ///
  /// Diferente de `substring` puro, nunca gera erro quando o texto possui
  /// menos de 40 caracteres: textos curtos são retornados sem reticências.
  static String resumir(String texto) {
    if (texto.length <= tamanhoMaximoResumo) {
      return texto;
    }
    return '${texto.substring(0, tamanhoMaximoResumo)}...';
  }

  /// Rótulo do autor a partir do `userId` da API (`Autor ID N`).
  static String _autorAPartirDe(dynamic userId) {
    final int? id = userId is int ? userId : int.tryParse('$userId');
    return 'Autor ID ${id ?? 0}';
  }

  static String _textoOuVazio(dynamic valor) =>
      valor is String ? valor : '';

  static String? _dataOpcional(dynamic valor) {
    if (valor is! String) {
      return null;
    }
    final String texto = valor.trim();
    return texto.isEmpty ? null : texto;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoticiaModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          titulo == other.titulo &&
          resumo == other.resumo &&
          conteudoCompleto == other.conteudoCompleto &&
          autor == other.autor &&
          urlImagem == other.urlImagem &&
          dataPublicacao == other.dataPublicacao;

  @override
  int get hashCode => Object.hash(
        id,
        titulo,
        resumo,
        conteudoCompleto,
        autor,
        urlImagem,
        dataPublicacao,
      );

  @override
  String toString() =>
      'NoticiaModel(id: $id, titulo: $titulo, autor: $autor)';
}
