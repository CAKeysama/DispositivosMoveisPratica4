import 'package:flutter/material.dart';

/// Imagem de capa com Hero Animation e fallback visual local.
///
/// Envolvendo a imagem em [Hero], a transição entre o feed e a tela de
/// detalhes é animada com a tag [heroTag] (id da notícia, único por item).
///
/// Se a imagem remota falhar, um placeholder visual estável é exibido:
/// a falha da imagem nunca impede a leitura da notícia.
class CapaNoticia extends StatelessWidget {
  /// URL da imagem remota.
  final String urlImagem;

  /// Tag do Hero (deve ser única por notícia: use o id).
  final Object heroTag;

  /// Altura desejada da imagem.
  final double altura;

  /// Largura desejada da imagem ([double.infinity] por padrão).
  final double largura;

  /// Como a imagem preenche o espaço.
  final BoxFit fit;

  /// Título usado no placeholder quando a imagem falha.
  final String? tituloPlaceholder;

  const CapaNoticia({
    super.key,
    required this.urlImagem,
    required this.heroTag,
    this.altura = 220,
    this.largura = double.infinity,
    this.fit = BoxFit.cover,
    this.tituloPlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;

    return Hero(
      tag: heroTag,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: largura,
          height: altura,
          child: Image.network(
            urlImagem,
            fit: fit,
            width: largura,
            height: altura,
            // Placeholder enquanto a imagem carrega: mantém o layout estável.
            loadingBuilder:
                (
                  BuildContext context,
                  Widget child,
                  ImageChunkEvent? progresso,
                ) {
                  if (progresso == null) {
                    return child;
                  }
                  return ColoredBox(
                    color: cores.surfaceContainerHighest,
                    child: const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    ),
                  );
                },
            // Fallback local quando a imagem remota falha.
            errorBuilder: (BuildContext context, Object erro, StackTrace? _) {
              return _PlaceholderCapa(
                titulo: tituloPlaceholder,
                cor: cores.surfaceContainerHighest,
                corIcone: cores.onSurfaceVariant,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PlaceholderCapa extends StatelessWidget {
  final String? titulo;
  final Color cor;
  final Color corIcone;

  const _PlaceholderCapa({
    required this.titulo,
    required this.cor,
    required this.corIcone,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: cor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.image_not_supported_outlined, size: 48, color: corIcone),
            const SizedBox(height: 8),
            Text(
              titulo == null
                  ? 'Imagem indisponível'
                  : 'Imagem indisponível\n$titulo',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: corIcone, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
